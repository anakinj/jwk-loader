# frozen_string_literal: true

require_relative "jwk_loader/version"
require_relative "jwk_loader/jwks"
require_relative "jwk_loader/jwks_uri_provider"
require_relative "jwk_loader/memory_cache"
require_relative "jwk_loader/error"

module JwkLoader
  def self.for_uri(**options)
    JwksUriProvider.new(**options)
  end
end
