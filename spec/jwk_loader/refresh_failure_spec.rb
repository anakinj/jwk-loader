# frozen_string_literal: true

RSpec.describe JwkLoader::JwksUriProvider, "refreshing cached keys" do
  subject(:provider) { JwkLoader.for_uri(uri: uri, cache: cache) }

  let(:uri) { "https://example.com/refresh-jwks" }
  let(:cache) { JwkLoader::MemoryCache.new }
  let(:now) { Time.at(1_700_000_000) }
  let(:cached_keys) { JWT::JWK::Set.new([]) }
  let(:cached_entry) { { jwks: cached_keys, fetched_at: now - 901 } }

  before do
    allow(Time).to receive(:now).and_return(now)
    cache.store(uri, cached_entry)
    allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_return(keys: [])
  end

  after { JwkLoader.memory_store.delete(uri) }

  %i[kid_not_found invalidate].each do |hint|
    it "preserves cached keys and their age after a failed #{hint} refresh, then retries" do
      failure = Net::OpenTimeout.new("fetch failed")
      allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_raise(failure)

      expect { provider.call(hint => true) }.to raise_error(failure)
      expect(cache.fetch(uri)).to equal(cached_entry)
      expect(cache.fetch(uri)[:fetched_at]).to eq(now - 901)
      expect(provider.call({})).to equal(cached_keys)

      allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_return(keys: [])
      refreshed = provider.call(hint => true)

      expect(refreshed).not_to equal(cached_keys)
      expect(cache.fetch(uri)[:jwks]).to equal(refreshed)
      expect(cache.fetch(uri)[:fetched_at]).to eq(now)
    end
  end

  context "when an unknown-key refresh receives an HTTP error" do
    let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }
    let(:cached_keys) { JWT::JWK::Set.new(keys: [jwk.export]) }
    let(:payload) { { "sub" => "cached-key" } }

    it "propagates the error while preserving the cache and verification with known keys" do
      allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_call_original
      stub_request(:get, uri).to_return(status: 503, body: '{"keys":[]}')
      unknown_token = JWT.encode(payload, jwk.keypair, "RS256", { kid: "unknown" })

      expect { JWT.decode(unknown_token, nil, true, algorithm: "RS256", jwks: provider) }
        .to(raise_error(Net::HTTPExceptions) do |error|
          expect(error.response.code).to eq("503")
        end)

      expect(cache.fetch(uri)).to equal(cached_entry)
      expect(cache.fetch(uri)[:fetched_at]).to eq(now - 901)

      known_token = JWT.encode(payload, jwk.keypair, "RS256", { kid: jwk.kid })
      expect(JWT.decode(known_token, nil, true, algorithm: "RS256", jwks: provider).first).to eq(payload)
      expect(WebMock).to have_requested(:get, uri).once
    end
  end

  it "keeps the previous set available until its replacement has been loaded" do
    allow(JwkLoader::Jwks).to receive(:from_uri).with(uri) do
      expect(cache.fetch(uri)).to equal(cached_entry)
      { keys: [] }
    end

    refreshed = provider.call(invalidate: true)

    expect(cache.fetch(uri)[:jwks]).to equal(refreshed)
    expect(refreshed).not_to equal(cached_keys)
  end

  it "does not refresh before the grace period has elapsed" do
    cached_entry[:fetched_at] = now - 899

    expect(provider.call(kid_not_found: true)).to equal(cached_keys)
    expect(JwkLoader::Jwks).not_to have_received(:from_uri)
  end

  it "refreshes when the grace period has elapsed exactly" do
    cached_entry[:fetched_at] = now - 900

    refreshed = provider.call(kid_not_found: true)

    expect(refreshed).not_to equal(cached_keys)
    expect(cache.fetch(uri)[:fetched_at]).to eq(now)
  end

  it "still prefers locally supplied test keys when invalidating a remote set" do
    local_keys = JWT::JWK::Set.new([])
    JwkLoader.memory_store.store(uri, local_keys)

    expect(provider.call(invalidate: true)).to equal(local_keys)
    expect(provider.call({})).to equal(local_keys)
    expect(cache.fetch(uri)).to be_nil
    expect(JwkLoader::Jwks).not_to have_received(:from_uri)
  end
end
