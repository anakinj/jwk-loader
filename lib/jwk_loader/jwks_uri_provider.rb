# frozen_string_literal: true

module JwkLoader
  def self.cache
    @cache ||= MemoryCache.new
  end

  class JwksUriProvider
    attr_reader :uri, :cache, :cache_grace_period

    def initialize(uri:, cache: JwkLoader.cache, cache_grace_period: 900)
      @uri          = uri
      @cache        = cache || MemoryCache.new
      @cache_grace_period = cache_grace_period
    end

    def call(options)
      invalidate_cache! if options[:kid_not_found] || options[:invalidate]
      jwks
    end

    private

    def jwks
      from_cache || from_uri
    end

    def invalidate_cache!
      return if Time.now - cache_entry.fetch(:fetched_at) < cache_grace_period

      cache.delete(uri)
    end

    def from_cache
      cache_entry&.fetch(:jwks)
    end

    def cache_entry
      cache.fetch(uri)
    end

    def from_uri
      JwkLoader::Jwks.from_uri(uri).tap do |jwks|
        cache.store(uri, jwks: jwks, fetched_at: Time.now)
      end
    end
  end
end
