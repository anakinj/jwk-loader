# frozen_string_literal: true

require "uri"
require "json"

module JwkLoader
  class JwkSet
    class << self
      def from_urk(jwk_set_url)
        jwk_set_url = URI.parse(jwk_set_url) unless jwk_set_url.is_a?(URI)
        jwk_set_url.open do |io|
          from_json(io.read)
        end
      end

      def from_json(jwk_set_json)
        jwk_set = JSON.parse(jwk_set_json, symbolize_names: true)
        new(jwk_set)
      end
    end

    attr_reader :jwks

    def initialize(jwks)
      @jwks = jwks[:keys]
    end
  end
end
