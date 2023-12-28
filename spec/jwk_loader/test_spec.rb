# frozen_string_literal: true

require "jwk_loader/test"

RSpec.describe JwkLoader::Test do
  subject(:test_context) do
    Class.new do
      include JwkLoader::Test
    end.new
  end

  describe "#sign_test_token" do
    context "when asked to sign a payload" do
      it "returns a signed token that can be verified" do
        token = test_context.sign_test_token(token_payload: {},
                                             jwk_endpoint: "https://example.com/.well-known/jwks.json",
                                             algorithm: "RS512")
        expect(token).to be_a(String)
        decoded_token = JWT.decode(token, nil, true, algorithm: "RS512", jwks: JwkLoader.for_uri(uri: "https://example.com/.well-known/jwks.json"))
        expect(decoded_token.first).to eq({})
      end
    end
  end
end
