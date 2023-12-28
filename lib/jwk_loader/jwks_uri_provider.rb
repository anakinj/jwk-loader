# frozen_string_literal: true

module JwkLoader
  class JwksUriProvider
    attr_reader :uri, :cache, :cache_grace_period

    def initialize(uri:, cache:, cache_grace_period:)
      @uri          = uri
      @cache        = cache
      @cache_grace_period = cache_grace_period
    end

    def call(options)
      invalidate_cache! if options[:kid_not_found] || options[:invalidate]
      jwks
    end

    private

    def jwks
      from_cache || from_memory || from_uri
    end

    def invalidate_cache!
      return if Time.now - cache_entry.fetch(:fetched_at) < cache_grace_period

      cache.delete(uri)
    end

    def from_cache
      cache_entry&.fetch(:jwks)
    end

    def from_memory
      JwkLoader::Jwks.from_memory(uri)
    end

    def cache_entry
      cache.fetch(uri)
    end

    def from_uri
      data = JwkLoader::Jwks.from_uri(uri)
      JWT::JWK::Set.new(data).tap do |jwks|
        cache.store(uri, jwks: jwks, fetched_at: Time.now)
      end
    end
  end
end
