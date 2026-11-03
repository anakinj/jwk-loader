# frozen_string_literal: true

module JwkLoader
  class JwksUriProvider
    attr_reader :uri, :cache, :cache_grace_period, :cache_max_age

    def initialize(uri:, cache:, cache_grace_period:, cache_max_age: nil)
      @uri          = uri
      @cache        = cache
      @cache_grace_period = cache_grace_period
      @cache_max_age = cache_max_age
      validate_cache_max_age!
    end

    def call(options)
      refreshed = refresh_cache! if options[:kid_not_found] || options[:invalidate]
      refreshed || jwks
    end

    private

    def validate_cache_max_age!
      return if cache_max_age.nil?
      return if cache_max_age.is_a?(Numeric) && cache_max_age.real? &&
                cache_max_age.finite? && cache_max_age >= 0

      raise ArgumentError, "cache_max_age must be nil or a finite non-negative number of seconds"
    end

    def jwks
      from_cache || from_memory || from_uri
    end

    def refresh_cache!
      entry = cache_entry
      return if entry.nil? || Time.now - entry.fetch(:fetched_at) < cache_grace_period

      if (keys = from_memory)
        cache.delete(uri)
        keys
      else
        from_uri
      end
    end

    def from_cache
      entry = cache_entry
      return if entry.nil?
      return if cache_max_age && Time.now - entry.fetch(:fetched_at) >= cache_max_age

      entry.fetch(:jwks)
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
