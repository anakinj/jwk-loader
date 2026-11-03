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
        expect(provider.cache_failure_cooldown).to eq(0)
      end
    end

    context "when configuration is given" do
      # rubocop:disable-next Lint/ConstantDefinitionInBlock, Lint/EmptyClass
      class YetAnotherCache; end

      let(:cache) { YetAnotherCache.new }
      let(:cache_grace_period) { 12_345 }
      let(:cache_failure_cooldown) { 30 }

      before do
        JwkLoader.configure do |cfg|
          cfg[:cache] = cache
          cfg[:cache_grace_period] = cache_grace_period
          cfg[:cache_failure_cooldown] = cache_failure_cooldown
        end
      end

      it "returns a provider with the given configuration" do
        expect(provider.cache).to be_a(YetAnotherCache)
        expect(provider.cache_grace_period).to eq(cache_grace_period)
        expect(provider.cache_failure_cooldown).to eq(cache_failure_cooldown)
      end

      context "when using accessors" do
        before do
          JwkLoader.configure do |cfg|
            cfg.cache = cache
            cfg.cache_grace_period = cache_grace_period
            cfg.cache_failure_cooldown = cache_failure_cooldown
          end
        end

        it "returns a provider with the given configuration" do
          expect(provider.cache).to be_a(YetAnotherCache)
          expect(provider.cache_grace_period).to eq(cache_grace_period)
          expect(provider.cache_failure_cooldown).to eq(cache_failure_cooldown)
        end
      end
    end
  end
end
