# frozen_string_literal: true

module JwkLoader
  module Test
    def generate_signing_key(algorithm:)
      case algorithm
      when "RS256", "RS384", "RS512"
        OpenSSL::PKey::RSA.new(2048)
      when "ES256"
        OpenSSL::PKey::EC.generate("prime256v1")
      else
        raise "Unsupported algorithm: #{algorithm}"
      end
    end

    def test_signing_key_for(jwk_endpoint:, algorithm: "RS512")
      key_set = JwkLoader.memory_store.fetch(jwk_endpoint)

      if key_set.nil?
        key_set = JWT::JWK::Set.new([generate_signing_key(algorithm: algorithm)])
        JwkLoader.memory_store.store(jwk_endpoint, key_set)
      end

      key_set.first
    end

    def sign_test_token(token_payload:, jwk_endpoint:, algorithm: "RS512")
      key = test_signing_key_for(jwk_endpoint: jwk_endpoint, algorithm: algorithm)
      JWT.encode(token_payload, key.signing_key, algorithm, kid: key[:kid])
    end
  end
end
