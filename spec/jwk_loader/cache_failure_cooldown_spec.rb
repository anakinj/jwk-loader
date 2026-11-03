# frozen_string_literal: true

RSpec.describe JwkLoader::JwksUriProvider, "cooling down after failed fetches" do
  subject(:provider) do
    JwkLoader.for_uri(uri: uri, cache: cache, cache_grace_period: 0, cache_failure_cooldown: 30)
  end

  let(:uri) { "https://example.com/failing-jwks" }
  let(:cache) { JwkLoader::MemoryCache.new }
  let(:now) { Time.at(1_700_000_000) }

  before do
    allow(Time).to receive(:now).and_return(now)
    stub_request(:get, uri).to_return(status: 503, body: '{"keys":[]}')
  end

  after { JwkLoader.memory_store.delete(uri) }

  it "stores the native failure with its completion time and shares it between providers" do
    stub_request(:get, uri).to_return do
      allow(Time).to receive(:now).and_return(now + 5)
      { status: 503, body: '{"keys":[]}' }
    end
    failure = nil
    expect { provider.call({}) }.to raise_error(Net::HTTPExceptions) { |error| failure = error }
    expect(cache.fetch(uri)).to eq(
      jwks: nil, fetched_at: nil,
      failure: { error: failure, failed_at: now + 5, consecutive_failures: 1 }
    )
    expect(failure.response.code).to eq("503")

    other_provider = JwkLoader.for_uri(uri: uri, cache: cache, cache_failure_cooldown: 30)
    allow(Time).to receive(:now).and_return(now + 34)
    expect { other_provider.call(invalidate: true) }.to raise_error(failure)
    expect(WebMock).to have_requested(:get, uri).once
    expect(cache.fetch(uri)[:failure][:consecutive_failures]).to eq(1)
  end

  it "timestamps the failure before reading from a slow cache backend" do
    load_completed = false
    stub_request(:get, uri).to_return do
      load_completed = true
      { status: 503, body: '{"keys":[]}' }
    end
    allow(cache).to receive(:fetch).and_wrap_original do |fetch, key|
      allow(Time).to receive(:now).and_return(now + 10) if load_completed
      fetch.call(key)
    end

    expect { provider.call({}) }.to raise_error(Net::HTTPExceptions)
    expect(cache.fetch(uri)[:failure][:failed_at]).to eq(now)
  end

  it "retries at the exact boundary, counts failed fetches, and resets failure state on success" do
    stub_request(:get, uri).to_return(
      { status: 503, body: '{"keys":[]}' },
      { status: 503, body: '{"keys":[]}' },
      { status: 200, body: '{"keys":[]}' },
      { status: 503, body: '{"keys":[]}' }
    )
    expect { provider.call({}) }.to raise_error(Net::HTTPExceptions)
    allow(Time).to receive(:now).and_return(now + 30)
    expect { provider.call(kid_not_found: true) }.to raise_error(Net::HTTPExceptions)
    expect(cache.fetch(uri)[:failure]).to include(failed_at: now + 30, consecutive_failures: 2)

    allow(Time).to receive(:now).and_return(now + 60)
    keys = provider.call({})
    expect(cache.fetch(uri)).to eq(jwks: keys, fetched_at: now + 60)

    allow(Time).to receive(:now).and_return(now + 61)
    expect { provider.call(invalidate: true) }.to raise_error(Net::HTTPExceptions)
    expect(cache.fetch(uri)).to include(jwks: keys, fetched_at: now + 60)
    expect(cache.fetch(uri)[:failure]).to include(failed_at: now + 61, consecutive_failures: 1)
    expect(WebMock).to have_requested(:get, uri).times(4)
  end

  it "does not share failures with a different URI or cache backend" do
    expect { provider.call({}) }.to raise_error(Net::HTTPExceptions)
    other_uri = "https://example.com/other-jwks"
    stub_request(:get, other_uri).to_return(status: 200, body: '{"keys":[]}')
    stub_request(:get, uri).to_return(status: 200, body: '{"keys":[]}')

    expect(JwkLoader.for_uri(uri: other_uri, cache: cache, cache_failure_cooldown: 30).call({}))
      .to be_a(JWT::JWK::Set)
    expect(JwkLoader.for_uri(uri: uri, cache: JwkLoader::MemoryCache.new, cache_failure_cooldown: 30).call({}))
      .to be_a(JWT::JWK::Set)
    expect(WebMock).to have_requested(:get, other_uri).once
    expect(WebMock).to have_requested(:get, uri).twice
  end

  it "keeps immediate retry behavior and does not cache failures by default" do
    default_provider = JwkLoader.for_uri(uri: uri, cache: cache)

    2.times { expect { default_provider.call({}) }.to raise_error(Net::HTTPExceptions) }
    expect(cache.fetch(uri)).to be_nil
    expect(WebMock).to have_requested(:get, uri).twice
  end

  it "allows zero to override a global cooldown" do
    JwkLoader.configure { |config| config.cache_failure_cooldown = 60 }
    immediate_provider = JwkLoader.for_uri(uri: uri, cache: cache, cache_failure_cooldown: 0)

    2.times { expect { immediate_provider.call({}) }.to raise_error(Net::HTTPExceptions) }
    expect(cache.fetch(uri)).to be_nil
    expect(WebMock).to have_requested(:get, uri).twice
  end

  it "rejects invalid cooldowns before loading keys" do
    [nil, -1, "30", false, Float::NAN, Float::INFINITY, Complex(1, 1)].each do |invalid|
      expect { JwkLoader.for_uri(uri: uri, cache: cache, cache_failure_cooldown: invalid) }
        .to raise_error(ArgumentError, /cache_failure_cooldown/)
    end
    expect(WebMock).not_to have_requested(:get, uri)
  end

  {
    JSON::ParserError => "{",
    JWT::JWKError => '{"keys":[{"kty":"RSA"}]}',
    ArgumentError => "5"
  }.each do |error_class, body|
    it "cools down after #{error_class} without changing the exception" do
      stub_request(:get, uri).to_return(status: 200, body: body)
      failure = nil
      expect { provider.call({}) }.to raise_error(error_class) { |error| failure = error }

      expect { provider.call({}) }.to raise_error(failure)
      expect(WebMock).to have_requested(:get, uri).once
    end
  end

  [Net::OpenTimeout, Zlib::DataError].each do |error_class|
    it "cools down after a native #{error_class} transport failure" do
      failure = error_class.new("fetch failed")
      stub_request(:get, uri).to_raise(failure)

      2.times { expect { provider.call({}) }.to raise_error(failure) }
      expect(WebMock).to have_requested(:get, uri).once
    end
  end

  it "uses locally supplied test keys during a cooldown without fetching" do
    expect { provider.call({}) }.to raise_error(Net::HTTPExceptions)
    local_keys = JWT::JWK::Set.new([])
    JwkLoader.memory_store.store(uri, local_keys)

    expect(provider.call(invalidate: true)).to equal(local_keys)
    expect(WebMock).to have_requested(:get, uri).once
  end

  it "does not treat cache read errors as loading failures" do
    allow(cache).to receive(:fetch).with(uri).and_raise(IOError, "cache read failed")
    expect(cache).not_to receive(:store)

    expect { provider.call({}) }.to raise_error(IOError, "cache read failed")
    expect(WebMock).not_to have_requested(:get, uri)
  end

  it "does not record a failed successful-cache write as a loading failure" do
    stub_request(:get, uri).to_return(status: 200, body: '{"keys":[]}')
    allow(cache).to receive(:store).and_raise(IOError, "cache write failed")

    expect { provider.call({}) }.to raise_error(IOError, "cache write failed")
    expect(cache).to have_received(:store).once
    expect(cache.fetch(uri)).to be_nil
  end

  it "surfaces failure-cache write errors with the loading error as their cause" do
    allow(cache).to receive(:store).and_raise(IOError, "cache write failed")

    expect { provider.call({}) }.to(raise_error(IOError, "cache write failed") do |error|
      expect(error.cause).to be_a(Net::HTTPExceptions)
    end)
    expect(cache).to have_received(:store).once
  end

  context "with a previously cached signing key" do
    let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }
    let(:cached_keys) { JWT::JWK::Set.new(keys: [jwk.export]) }
    let(:fetched_at) { now - 901 }
    let(:payload) { { "sub" => "cached-key" } }
    let(:unknown_token) { JWT.encode(payload, jwk.keypair, "RS256", { kid: "unknown" }) }

    before { cache.store(uri, jwks: cached_keys, fetched_at: fetched_at) }

    %i[kid_not_found invalidate].each do |hint|
      it "preserves usable keys and their timestamp during a failed #{hint} refresh" do
        failure = nil
        expect { provider.call(hint => true) }.to raise_error(Net::HTTPExceptions) { |error| failure = error }
        expect { provider.call(hint => true) }.to raise_error(failure)
        expect(provider.call({})).to equal(cached_keys)
        expect(cache.fetch(uri)).to include(jwks: cached_keys, fetched_at: fetched_at)
        expect(WebMock).to have_requested(:get, uri).once
      end
    end

    it "propagates the cached refresh error through JWT.decode but still verifies known keys" do
      failure = nil
      expect { JWT.decode(unknown_token, nil, true, algorithm: "RS256", jwks: provider) }
        .to raise_error(Net::HTTPExceptions) { |error| failure = error }
      expect { JWT.decode(unknown_token, nil, true, algorithm: "RS256", jwks: provider) }
        .to raise_error(failure)

      token = JWT.encode(payload, jwk.keypair, "RS256", { kid: jwk.kid })
      expect(JWT.decode(token, nil, true, algorithm: "RS256", jwks: provider).first).to eq(payload)
      expect(cache.fetch(uri)).to include(jwks: cached_keys, fetched_at: fetched_at)
      expect(WebMock).to have_requested(:get, uri).once
    end

    it "does not count a successfully fetched set missing the requested kid as a failure" do
      stub_request(:get, uri).to_return(status: 200, body: JSON.generate(keys: [jwk.export]))

      2.times do
        expect { JWT.decode(unknown_token, nil, true, algorithm: "RS256", jwks: provider) }
          .to raise_error(JWT::DecodeError, /Could not find public key for kid/)
      end
      expect(cache.fetch(uri)).to include(fetched_at: now)
      expect(cache.fetch(uri)).not_to have_key(:failure)
      expect(WebMock).to have_requested(:get, uri).twice
    end
  end
end
