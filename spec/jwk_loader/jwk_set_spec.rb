# frozen_string_literal: true

RSpec.describe JwkLoader::JwkSet do
  describe ".from_json" do
    context "when json is missing the keys property" do
      let(:jwks_json) { JSON.dump(eys: [{}, {}]) }
      it "raises an error" do
        expect do
          described_class.from_json(jwks_json)
        end.to raise_error(JwkLoader::JwkSetError, "JWK Set must have a keys property")
      end
    end
  end

  describe ".from_url" do
    it "loads the JWK set from a URL", vcr: { cassette_name: "google_certs" } do
      jwk_set = described_class.from_url("https://www.googleapis.com/oauth2/v3/certs")
      expect(jwk_set.jwks.size).to eq(2)
      expect(jwk_set.jwks.first).to be_a(JWT::JWK::RSA)
    end
  end
end
