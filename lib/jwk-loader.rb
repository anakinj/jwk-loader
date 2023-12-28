# frozen_string_literal: true

require_relative "jwk_loader/version"
require_relative "jwk_loader/jwks"
require_relative "jwk_loader/jwks_uri_provider"
require_relative "jwk_loader/memory_cache"
require_relative "jwk_loader/error"
require_relative "jwk_loader/config/config"

module JwkLoader
  class << self
    def for_uri(**options)
      options[:cache] ||= config[:cache]
      options[:cache_grace_period] ||= config[:cache_grace_period]
      JwksUriProvider.new(**options)
    end

    def cache
      config[:cache]
    end

    def configure
      yield config
    end

    def config
      @config ||= JwkLoader::Config.new.tap do |cfg|
        cfg[:cache] = MemoryCache.new
        cfg[:cache_grace_period] = 900
      end
    end

    def reset!
      @config = nil
    end

    def memory_store
      @memory_store ||= MemoryCache.new
    end
  end
end
