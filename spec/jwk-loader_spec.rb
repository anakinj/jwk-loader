# frozen_string_literal: true

RSpec.describe JwkLoader do
  describe ".configure" do
    it "yields config" do
      expect { |b| JwkLoader.configure(&b) }.to yield_with_args(JwkLoader::Config)
    end
  end

  describe ".for_uri" do
    subject(:provider) { JwkLoader.for_uri(uri: "an uri here") }

    before { JwkLoader.instance_variable_set(:@config, nil) }

    context "when no configuration is given" do
      it "returns a provider with the default configuration" do
        expect(provider.cache).to be_a(JwkLoader::MemoryCache)
        expect(provider.cache_grace_period).to eq(900)
      end
    end

    context "when configuration is given" do
      # rubocop:disable Lint/ConstantDefinitionInBlock, Lint/EmptyClass
      class YetAnotherCache; end
      # rubocop:enable Lint/ConstantDefinitionInBlock, Lint/EmptyClass

      let(:cache) { YetAnotherCache.new }
      let(:cache_grace_period) { 12_345 }

      before do
        JwkLoader.configure do |cfg|
          cfg[:cache] = cache
          cfg[:cache_grace_period] = cache_grace_period
        end
      end

      it "returns a provider with the given configuration" do
        expect(provider.cache).to be_a(YetAnotherCache)
        expect(provider.cache_grace_period).to eq(cache_grace_period)
      end

      context "when using accessors" do
        before do
          JwkLoader.configure do |cfg|
            cfg.cache = cache
            cfg.cache_grace_period = cache_grace_period
          end
        end

        it "returns a provider with the given configuration" do
          expect(provider.cache).to be_a(YetAnotherCache)
          expect(provider.cache_grace_period).to eq(cache_grace_period)
        end
      end
    end
  end
end
