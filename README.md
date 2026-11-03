# jwk-loader

[![Gem Version](https://badge.fury.io/rb/jwk-loader.svg)](https://badge.fury.io/rb/jwk-loader)
[![Build status](https://github.com/anakinj/jwk-loader/actions/workflows/test.yml/badge.svg)](https://github.com/anakinj/jwk-loader/actions/workflows/test.yml)

This gem can be used in combination with the [ruby-jwt](https://rubygems.org/gems/jwt) gem as the mechanism to load and cache the JWKs.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jwk-loader

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jwk-loader

## Usage

### Using as a jwks loader when decoding JWT tokens

```ruby
require "jwt"
require "jwk-loader"

JWT.decode(token, nil, true, algorithm: "RS512", jwks: JwkLoader.for_uri(uri: "https://url/to/public/jwks") )
```

### Handling loading errors

Non-2xx JWKS responses raise native HTTP errors before JSON parsing; handle `Net::HTTPExceptions` alongside `JWT::DecodeError`. Invalid URIs, connection/TLS failures, timeouts, malformed JSON, and invalid keys propagate unchanged; examples include `URI::InvalidURIError`, `Net::OpenTimeout`, `JSON::ParserError`, or `JWT::JWKError`.

```ruby
class AuthenticationError < StandardError; end

begin
  JWT.decode(token, nil, true, algorithm: "RS512", jwks: JwkLoader.for_uri(uri: jwks_uri))
rescue Net::HTTPExceptions, JWT::DecodeError => error
  raise AuthenticationError, "Token verification failed", cause: error
end
```

### Testing endpoints protected by JWT tokens

When testing HTTP endpoints protected by asymmetric JWT keys the mechanism in `jwk_loader/test` can be used to simplify the process.

```ruby
require 'jwk_loader/test'

RSpec.describe 'GET /protected' do
  include JwkLoader::Test

  context 'when called with a valid token' do
    let(:token) { sign_test_token(token_payload: { user_id: "user" }, jwk_endpoint: "https://url/to/public/jwks") }
    subject(:response) { get('/protected', { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }) }

    it 'is a success' do
      expect(response.status).to eq(200)
    end
  end
end
```

### Configuring the gem

The default `cache_grace_period` is 900 seconds, measured from the last successful fetch. An unknown-key or explicit invalidation hint can refresh a cached set once that period has elapsed; it is a refresh cooldown, not a maximum lifetime for known keys. Refreshing leaves the previous cached set available until its replacement has loaded successfully.

```ruby
require "jwt-loader"

JwkLoader.configure do |config|
  config[:cache] = YetAnotherCache.new
  config[:cache_grace_period] = 999
  config[:cache_failure_cooldown] = 30
end
```

or in alternative

```ruby
require "jwt-loader"

JwkLoader.configure do |config|
  config.cache = YetAnotherCache.new
  config.cache_grace_period = 999
  config.cache_failure_cooldown = 30
end
```

A failed refresh propagates the original loading exception for both `kid_not_found` and `invalidate` hints, without deleting the previous set or changing its timestamp. The triggering `JWT.decode` call fails with that exception. Subsequent ordinary lookups can still use the preserved keys.

`cache_failure_cooldown` optionally delays retries after HTTP, connection/TLS, timeout, decompression, URI, JSON, or JWK loading errors. It defaults to `0`, preserving immediate retries without caching failures. Use a finite non-negative number of seconds, globally as above or per provider:

```ruby
JwkLoader.for_uri(uri: jwks_uri, cache_failure_cooldown: 30)
JwkLoader.for_uri(uri: jwks_uri, cache_failure_cooldown: 0)
```

During the cooldown, a lookup that would fetch the URI raises the cached native loading exception without another request. Ordinary cached-key lookups and locally supplied test keys remain usable. Retries are allowed once the cooldown has elapsed since the last failed fetch completed; a successful fetch clears failure state. A successful response missing a requested `kid` is not a loading failure. This does not coalesce concurrent fetches or implement exponential backoff.

Each URI's cache entry retains `jwks` and `fetched_at` from the last successful fetch, plus an optional `failure` hash containing `error`, `failed_at`, and `consecutive_failures`. Before any successful fetch, `jwks` and `fetched_at` are `nil`. Only actual failed fetches increment the count, not lookups suppressed by the cooldown; success resets it. Keeping failure results, timestamps, and counts in the shared cache allows providers using the same backend to share cooldown state and leaves the state needed for future exponential backoff. Custom cache backends must retain Ruby exception objects as well as key sets and timestamps; cache-backend errors propagate rather than being cached as loading failures.

Invalidation hints are safe when the cache entry is absent or has been evicted: the provider performs an ordinary lookup, using locally supplied test keys or fetching the URI when needed.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anakinj/jwk-loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/anakinj/jwk-loader/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jwk::Loader project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abajubh/jwk-loader/blob/main/CODE_OF_CONDUCT.md).
