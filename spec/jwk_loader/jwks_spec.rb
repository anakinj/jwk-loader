# frozen_string_literal: true

RSpec.describe JwkLoader::Jwks do
  let(:uri) { "https://example.com/jwks" }

  describe ".from_uri" do
    it "parses successful responses" do
      stub_request(:get, uri).to_return(status: 200, body: '{"keys":[]}')

      expect(described_class.from_uri(uri)).to eq(keys: [])
    end

    [301, 404, 429, 500].each do |status|
      it "rejects HTTP #{status} even when the response is valid JSON" do
        stub_request(:get, uri).to_return(status: status, body: '{"keys":[]}')
        expect(described_class).not_to receive(:from_json)

        expect { described_class.from_uri(uri) }
          .to(raise_error(Net::HTTPExceptions) do |error|
            expect(error.response.uri.to_s).to eq(uri)
            expect(error.response.code).to eq(status.to_s)
          end)
      end
    end

    it "rejects an HTTP error before attempting to parse a non-JSON body" do
      stub_request(:get, uri).to_return(status: 503, body: "<html>Service unavailable</html>")

      expect { described_class.from_uri(uri) }
        .to raise_error(Net::HTTPExceptions)
    end

    it "exposes the endpoint through the native exception without adding it or the body to the message" do
      endpoint = URI("#{uri}?issuer=one")
      stub_request(:get, endpoint.to_s).to_return(status: 503, body: "private upstream response")

      expect { described_class.from_uri(endpoint) }
        .to(raise_error(Net::HTTPExceptions) do |error|
          expect(error.response.uri).to eq(endpoint)
          expect(error.response.code).to eq("503")
          expect(error.message).not_to include("example.com", "private upstream response")
        end)
    end

    it "preserves native JSON parsing errors for successful HTTP responses" do
      stub_request(:get, uri).to_return(status: 200, body: "not JSON")

      expect { described_class.from_uri(uri) }.to raise_error(JSON::ParserError)
    end

    [
      Net::OpenTimeout.new("connection timed out"),
      Zlib::DataError.new("invalid compressed response")
    ].each do |failure|
      it "preserves the original #{failure.class}" do
        stub_request(:get, uri).to_raise(failure)

        expect { described_class.from_uri(uri) }.to(raise_error do |error|
          expect(error).to equal(failure)
        end)
      end
    end

    it "does not add validation for successfully parsed JSON" do
      stub_request(:get, uri).to_return(status: 200, body: '{"error":"unavailable"}')

      expect(described_class.from_uri(uri)).to eq(error: "unavailable")
    end

    it "does not cache HTTP failures and retries on an ordinary lookup" do
      stub_request(:get, uri).to_return(
        { status: 503, body: '{"error":"unavailable"}' },
        { status: 200, body: '{"keys":[]}' }
      )
      provider = JwkLoader.for_uri(uri: uri)

      expect { provider.call({}) }.to raise_error(Net::HTTPExceptions)
      expect(provider.cache.fetch(uri)).to be_nil
      expect(provider.call({})).to be_a(JWT::JWK::Set)
      expect(WebMock).to have_requested(:get, uri).twice
    end
  end
end
