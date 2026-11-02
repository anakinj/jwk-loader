# frozen_string_literal: true

RSpec.describe JwkLoader::JwksUriProvider, "invalidating an absent cache entry" do
  subject(:provider) { JwkLoader.for_uri(uri: uri, cache: cache) }

  let(:uri) { "https://example.com/invalidation-jwks" }
  let(:cache) { JwkLoader::MemoryCache.new }

  before do
    allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_return(keys: [])
  end

  after { JwkLoader.memory_store.delete(uri) }

  %i[kid_not_found invalidate].each do |hint|
    it "loads and caches keys when #{hint} is received before the first lookup" do
      loaded = provider.call(hint => true)

      expect(loaded).to be_a(JWT::JWK::Set)
      expect(cache.fetch(uri)[:jwks]).to equal(loaded)
      expect(JwkLoader::Jwks).to have_received(:from_uri).with(uri).once
    end
  end

  it "reloads if another lookup evicts the entry before an invalidation hint" do
    first = provider.call({})
    cache.delete(uri)

    refreshed = provider.call(kid_not_found: true)

    expect(refreshed).not_to equal(first)
    expect(cache.fetch(uri)[:jwks]).to equal(refreshed)
    expect(JwkLoader::Jwks).to have_received(:from_uri).with(uri).twice
  end

  it "still uses locally supplied test keys when the cache entry is absent" do
    local_keys = JWT::JWK::Set.new([])
    JwkLoader.memory_store.store(uri, local_keys)

    expect(provider.call(invalidate: true)).to equal(local_keys)
    expect(JwkLoader::Jwks).not_to have_received(:from_uri)
  end

  it "propagates loading errors rather than treating a missing entry as a successful lookup" do
    failure = JwkLoader::JwksLoadError.new("fetch failed")
    allow(JwkLoader::Jwks).to receive(:from_uri).with(uri).and_raise(failure)

    expect { provider.call(invalidate: true) }.to raise_error(failure)
    expect(cache.fetch(uri)).to be_nil
  end
end
