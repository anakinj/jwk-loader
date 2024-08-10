# frozen_string_literal: true

module JwkLoader
  class Config
    class ConfigurationNotFound < JwkLoader::Error
      def initialize(key)
        super("Configuration for #{key} not available")
      end
    end

    def []=(key, value)
      registry[key] = value
    end

    def [](key)
      registry[key] || (raise ConfigurationNotFound, key)
    end

    def method_missing(name, *args)
      return send(:[]=, name.to_s[0..-2].to_sym, *args) if name.to_s.end_with?("=")

      send(:[], name, *args)
    end

    def respond_to_missing?(_name, _include_private)
      true
    end

    private

    def registry
      @registry ||= {}
    end
  end
end
