# frozen_string_literal: true

require "uri"
require "json"
require "net/http"

module JwkLoader
  module Jwks
    class << self
      def from_uri(uri)
        uri = URI.parse(uri) unless uri.is_a?(URI)

        response = Net::HTTP.get_response(uri)
        from_json(response.body)
      end

      def from_json(jwks_json)
        JSON.parse(jwks_json, symbolize_names: true)
      end
    end
  end
end
