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

```ruby
require "jwt-loader"

JwkLoader.configure do |config|
  config[:cache] = YetAnotherCache.new
  config[:cache_grace_period] = 999
end
```

or in alternative

```ruby
require "jwt-loader"

JwkLoader.configure do |config|
  config.cache = YetAnotherCache.new
  config.cache_grace_period = 999
end
```


## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anakinj/jwk-loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/anakinj/jwk-loader/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jwk::Loader project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abajubh/jwk-loader/blob/main/CODE_OF_CONDUCT.md).
