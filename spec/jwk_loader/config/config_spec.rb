# frozen_string_literal: true

RSpec.describe JwkLoader::Config do
  subject(:config) { JwkLoader::Config.new }

  describe ".[]=" do
    let(:key) { "a_key" }
    let(:value) { "a_value" }

    it "adds a configuration for a name" do
      config[key] = value
      expect(config[key]).to eq(value)
    end
  end

  describe ".[]" do
    it "raises an expection when a key is not present" do
      expect { config["key"] }.to raise_error(JwkLoader::Config::ConfigurationNotFound)
    end
  end

  describe ".some_value_123" do
    let(:value) { Object.new }

    it "adds a cache configuration" do
      config.some_value_123 = value
      expect(config.some_value_123).to be(value)
    end
  end

  describe ".foo(1)" do
    it "raises an ArgumentError" do
      expect { config.foo(1) }.to raise_error(ArgumentError)
    end
  end
end
