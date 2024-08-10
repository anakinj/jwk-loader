# frozen_string_literal: true

RSpec.describe JwkLoader::JwksUriProvider do
  let(:jwk) do
    JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
  end

  let(:token) { JWT.encode({ "pay" => "load" }, jwk.keypair, "RS512", { kid: jwk.kid }) }
  let(:cache) { JwkLoader.cache }

  subject(:jwks_provider) { JwkLoader.for_uri(uri: "https://www.googleapis.com/oauth2/v3/certs", cache: cache) }

  before do
    allow(JwkLoader::Jwks).to receive(:from_uri).and_call_original
  end

  context "when kid is found but the private key does not match with the public key" do
    let(:jwk) do
      JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), "1549e0aef574d1c7bdd136c202b8d290580b165c") # Fake the google jwk kid
    end
    it "can be used as the jwks loader", vcr: { cassette_name: "google_certs" } do
      expect do
        JWT.decode(token, nil, true, algorithm: "RS512",
                                     jwks: jwks_provider)
      end.to raise_error(JWT::VerificationError, "Signature verification failed")
    end
  end

  context "when kid is not found and cache is fresh" do
    it "does not load the jwks from the uri", vcr: { cassette_name: "google_certs" } do
      expect do
        JWT.decode(token, nil, true, algorithm: "RS512",
                                     jwks: jwks_provider)
      end.to raise_error(JWT::DecodeError, /Could not find public key for kid/)

      expect(JwkLoader::Jwks).to have_received(:from_uri).once
    end
  end

  context "when kid is not found and cache is old" do
    let(:cache) { JwkLoader::MemoryCache.new }

    it "loads the jwks from the uri", vcr: { cassette_name: "google_certs_twice" } do
      expect do
        JWT.decode(token, nil, true, algorithm: "RS512",
                                     jwks: jwks_provider)
      end.to raise_error(JWT::DecodeError, /Could not find public key for kid/)

      cache.fetch(jwks_provider.uri)[:fetched_at] = Time.now - (jwks_provider.cache_grace_period + 1)

      expect do
        JWT.decode(token, nil, true, algorithm: "RS512",
                                     jwks: jwks_provider)
      end.to raise_error(JWT::DecodeError, /Could not find public key for kid/)

      expect(JwkLoader::Jwks).to have_received(:from_uri).twice
    end
  end
end
