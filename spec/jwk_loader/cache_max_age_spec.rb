# frozen_string_literal: true

RSpec.describe JwkLoader::JwksUriProvider, "limiting cached key age" do
  subject(:provider) { JwkLoader.for_uri(uri: uri, cache: cache, cache_max_age: 300) }

  let(:uri) { "https://example.com/expiring-jwks" }
  let(:cache) { JwkLoader::MemoryCache.new }
  let(:now) { Time.at(1_700_000_000) }
  let(:cached_keys) { JWT::JWK::Set.new([]) }
  let(:cached_entry) { { jwks: cached_keys, fetched_at: now - 299 } }

  before do
    allow(Time).to receive(:now).and_return(now)
    cache.store(uri, cached_entry)
    stub_request(:get, uri).to_return(status: 200, body: '{"keys":[]}')
  end

  after { JwkLoader.memory_store.delete(uri) }

  it "retains indefinite caching when no maximum age is configured" do
    cached_entry[:fetched_at] = now - 10_000
    default_provider = JwkLoader.for_uri(uri: uri, cache: cache)

    expect(default_provider.call({})).to equal(cached_keys)
    expect(WebMock).not_to have_requested(:get, uri)
  end

  it "reuses unexpired keys and refreshes at the exact age limit despite the grace period" do
    expect(provider.call({})).to equal(cached_keys)
    expect(WebMock).not_to have_requested(:get, uri)

    allow(Time).to receive(:now).and_return(now + 1)
    refreshed = provider.call({})

    expect(refreshed).not_to equal(cached_keys)
    expect(cache.fetch(uri)).to eq(jwks: refreshed, fetched_at: now + 1)
    expect(WebMock).to have_requested(:get, uri).once
  end

  %i[kid_not_found invalidate].each do |hint|
    it "refreshes expired keys for #{hint} even within the grace period" do
      cached_entry[:fetched_at] = now - 300

      expect(provider.call(hint => true)).not_to equal(cached_keys)
      expect(WebMock).to have_requested(:get, uri).once
    end
  end

  it "still refreshes unexpired keys for an unknown key once the grace period has elapsed" do
    cached_entry[:fetched_at] = now - 901
    long_lived_provider = JwkLoader.for_uri(uri: uri, cache: cache, cache_max_age: 3600)

    expect(long_lived_provider.call(kid_not_found: true)).not_to equal(cached_keys)
    expect(WebMock).to have_requested(:get, uri).once
  end

  it "uses locally supplied test keys instead of fetching an expired remote set" do
    cached_entry[:fetched_at] = now - 300
    local_keys = JWT::JWK::Set.new([])
    JwkLoader.memory_store.store(uri, local_keys)

    expect(provider.call({})).to equal(local_keys)
    expect(WebMock).not_to have_requested(:get, uri)
  end

  it "refreshes on every lookup when the maximum age is zero" do
    uncached_provider = JwkLoader.for_uri(uri: uri, cache: cache, cache_max_age: 0)
    first = uncached_provider.call({})

    expect(uncached_provider.call({})).not_to equal(first)
    expect(WebMock).to have_requested(:get, uri).twice
  end

  it "rejects invalid maximum ages before loading keys" do
    [-1, "300", false, Float::NAN, Float::INFINITY, Complex(1, 1)].each do |invalid|
      expect { JwkLoader.for_uri(uri: uri, cache: cache, cache_max_age: invalid) }
        .to raise_error(ArgumentError, /cache_max_age/)
    end
    expect(WebMock).not_to have_requested(:get, uri)
  end

  context "with a global maximum age" do
    before { JwkLoader.configure { |config| config.cache_max_age = 10 } }

    it "applies the configured maximum age when no per-URI override is supplied" do
      configured_provider = JwkLoader.for_uri(uri: uri, cache: cache)

      expect(configured_provider.call({})).not_to equal(cached_keys)
      expect(WebMock).to have_requested(:get, uri).once
    end

    [nil, 600].each do |override|
      it "allows a per-URI #{override.inspect} to override the global age limit" do
        overridden_provider = JwkLoader.for_uri(uri: uri, cache: cache, cache_max_age: override)

        expect(overridden_provider.call({})).to equal(cached_keys)
        expect(WebMock).not_to have_requested(:get, uri)
      end
    end
  end

  context "for a known signing key" do
    let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }
    let(:cached_keys) { JWT::JWK::Set.new(keys: [jwk.export]) }
    let(:payload) { { "sub" => "cached-key" } }
    let(:token) { JWT.encode(payload, jwk.keypair, "RS256", { kid: jwk.kid }) }

    it "stops trusting a removed key once the set expires" do
      expect(JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider).first).to eq(payload)
      allow(Time).to receive(:now).and_return(now + 1)

      expect { JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider) }
        .to raise_error(JWT::DecodeError)
      expect(WebMock).to have_requested(:get, uri).once
    end

    it "loads changed key material even when the key ID has not changed" do
      replacement = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), jwk.kid)
      stub_request(:get, uri).to_return(status: 200, body: JSON.generate(keys: [replacement.export]))
      replacement_token = JWT.encode(payload, replacement.keypair, "RS256", { kid: jwk.kid })
      allow(Time).to receive(:now).and_return(now + 1)

      expect(JWT.decode(replacement_token, nil, true, algorithm: "RS256", jwks: provider).first).to eq(payload)
      expect { JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider) }
        .to raise_error(JWT::VerificationError)
      expect(WebMock).to have_requested(:get, uri).once
    end

    it "fails closed on each expired lookup until a refresh succeeds" do
      allow(Time).to receive(:now).and_return(now + 1)
      stub_request(:get, uri).to_return(
        { status: 503, body: '{"keys":[]}' },
        { status: 503, body: '{"keys":[]}' },
        { status: 200, body: JSON.generate(keys: [jwk.export]) }
      )

      2.times do
        expect { JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider) }
          .to raise_error(Net::HTTPExceptions)
        expect(cache.fetch(uri)).to equal(cached_entry)
        expect(cache.fetch(uri)[:fetched_at]).to eq(now - 299)
      end

      expect(JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider).first).to eq(payload)
      expect(cache.fetch(uri)[:fetched_at]).to eq(now + 1)
      expect(WebMock).to have_requested(:get, uri).times(3)
    end
  end
end
