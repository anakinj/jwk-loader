# frozen_string_literal: true

RSpec.describe JwkLoader::JwkSet do
  let(:jwks_json) { JSON.dump(keys: [{}, {}]) }
  describe ".from_json" do
    it "parses a set of JWK keys" do
      jwk_set = described_class.from_json(jwks_json)
      expect(jwk_set.jwks.size).to eq(2)
    end
  end
end
