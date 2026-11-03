# frozen_string_literal: true

module JwkLoader
  class JwksUriProvider
    attr_reader :uri, :cache, :cache_grace_period, :cache_failure_cooldown

    def initialize(uri:, cache:, cache_grace_period:, cache_failure_cooldown: 0)
      @uri          = uri
      @cache        = cache
      @cache_grace_period = cache_grace_period
      @cache_failure_cooldown = cache_failure_cooldown
      validate_cache_failure_cooldown!
    end

    def call(options)
      refreshed = refresh_cache! if options[:kid_not_found] || options[:invalidate]
      refreshed || jwks
    end

    private

    def validate_cache_failure_cooldown!
      return if cache_failure_cooldown.is_a?(Numeric) && cache_failure_cooldown.real? &&
                cache_failure_cooldown.finite? && cache_failure_cooldown >= 0

      raise ArgumentError, "cache_failure_cooldown must be a finite non-negative number of seconds"
    end

    def jwks
      from_cache || from_memory || from_uri
    end

    def refresh_cache!
      entry = cache_entry
      return if entry.nil? || entry.fetch(:jwks).nil? ||
                Time.now - entry.fetch(:fetched_at) < cache_grace_period

      if (keys = from_memory)
        cache.delete(uri)
        keys
      else
        from_uri
      end
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
      failure = cached_failure
      raise failure.fetch(:error) if failure

      jwks = load_jwks
      cache.store(uri, jwks: jwks, fetched_at: Time.now)
      jwks
    end

    def cached_failure
      return if cache_failure_cooldown.zero?

      failure = cache_entry&.fetch(:failure, nil)
      failure if failure && Time.now - failure.fetch(:failed_at) < cache_failure_cooldown
    end

    def load_jwks
      JWT::JWK::Set.new(JwkLoader::Jwks.from_uri(uri))
    rescue Net::ProtocolError, Timeout::Error, SocketError, IOError, SystemCallError, Zlib::Error,
           OpenSSL::OpenSSLError, URI::InvalidURIError, JSON::ParserError, JWT::DecodeError, ArgumentError => e
      cache_failure(e, failed_at: Time.now) if cache_failure_cooldown.positive?
      raise
    end

    def cache_failure(error, failed_at:)
      entry = cache_entry || { jwks: nil, fetched_at: nil }
      previous = entry[:failure]
      count = previous ? previous.fetch(:consecutive_failures) + 1 : 1
      failure = { error: error, failed_at: failed_at, consecutive_failures: count }
      cache.store(uri, entry.merge(failure: failure))
    end
  end
end
