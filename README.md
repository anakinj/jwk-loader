# JwkLoader

This gem can be used in combination with the [jwt](https://rubygems.org/gems/jwt) gem as the mechanism to load and cache the JWKs in the application.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jwk-loader

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jwk-loader

## Usage

### Using as a jwks loader when decoding JWT tokens

```
require "jwt"
require "jwk-loader"

JWT.decode(token, nil, true, algorithm: "RS512", jwks: JwkLoader.for_uri(uri: "https://url/to/public/jwks") )
```

### Configuring the gem

```ruby
require "jwt-loader"

JwkLoader.configure do |config|
  config[:cache] = YetAnotherCache.new
  config[:cache_grace_period] = 999
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
