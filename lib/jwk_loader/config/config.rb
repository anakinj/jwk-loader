# frozen_string_literal: true

module JwkLoader
  class Config
    class ConfigurationNotFound < JwkLoader::Error
      def initialize(key)
        super "Configuration for #{key} not available"
      end
    end

    def []=(key, value)
      registry[key] = value
    end

    def [](key)
      registry[key] || (raise ConfigurationNotFound, key)
    end

    private

    def registry
      @registry ||= {}
    end
  end
end
