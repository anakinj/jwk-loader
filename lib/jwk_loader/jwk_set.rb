# frozen_string_literal: true

require "uri"
require "json"

module JwkLoader
  class JwkSet
    class << self
      def from_url(jwk_set_url)
        jwk_set_url = URI.parse(jwk_set_url) unless jwk_set_url.is_a?(URI)

        response = Net::HTTP.get_response(jwk_set_url)
        from_json(response.body)
      end

      def from_json(jwk_set_json)
        from_hash(JSON.parse(jwk_set_json, symbolize_names: true))
      end

      def from_hash(jwk_set_hash)
        new(jwk_set_hash)
      end
    end

    attr_reader :jwks, :keys

    def initialize(jwks)
      raise JwkSetError, "JWK Set must have a keys property" unless jwks.key?(:keys)

      @keys = jwks[:keys]
      @jwks = @keys.map { |key| ::JWT::JWK.import(key) }
    end
  end
end
