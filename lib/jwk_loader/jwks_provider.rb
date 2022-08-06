# frozen_string_literal: true

module JwkLoader
  class JwksProvider
    def initialize(uri:)
      @uri = uri
    end

    def call(_options)
      jwks
    end

    private

    attr_reader :uri

    def jwks
      @jwks ||= JwkLoader::Jwks.from_uri(uri)
    end
  end
end
