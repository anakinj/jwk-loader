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
end
