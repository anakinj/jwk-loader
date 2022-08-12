# frozen_string_literal: true

require "concurrent/hash"

module JwkLoader
  class MemoryCache
    def initialize
      @data = ::Concurrent::Hash.new
    end

    def fetch(key)
      data.fetch(key, nil)
    end

    def store(key, value)
      data.store(key, value)
    end

    def delete(key)
      data.delete(key)
    end

    def clear
      data.clear
    end

    private

    attr_reader :data
  end
end
