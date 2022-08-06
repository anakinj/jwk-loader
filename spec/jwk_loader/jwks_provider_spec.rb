# frozen_string_literal: true

RSpec.describe JwkLoader::JwksProvider do
  context "when used in combination with the JWT.decode method" do
    it "can be used as the jwks loader", vcr: { cassette_name: "google_certs" } do
      jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), "1549e0aef574d1c7bdd136c202b8d290580b165c") # Fake the google jwk

      payload = { "pay" => "load" }
      headers = { kid: jwk.kid }

      token = JWT.encode(payload, jwk.keypair, "RS512", headers)

      jwk_provider = JwkLoader::JwksProvider.new(uri: "https://www.googleapis.com/oauth2/v3/certs")

      expect do
        JWT.decode(token, nil, true, algorithm: "RS512",
                                     jwks: jwk_provider)
      end.to raise_error(JWT::VerificationError, "Signature verification failed")
    end
  end
end
