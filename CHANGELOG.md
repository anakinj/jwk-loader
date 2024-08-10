# Changelog

## [1.1.0](https://github.com/anakinj/jwk-loader/compare/v1.0.0...v1.1.0) (2024-08-10)


### Features

* Official support for Ruby 3.2 and 3.3 ([2f6079f](https://github.com/anakinj/jwk-loader/commit/2f6079fd490a4918524974ffb1d897abbf875787))

## [1.0.0](https://github.com/anakinj/jwk-loader/compare/v0.1.1...v1.0.0) (2023-12-28)

### Features

- `jwk_loader/test` for convenience for testing without external dependencies. [#6](https://github.com/anakinj/jwk-loader/pull/6) ([@anakinj](https://github.com/anakinj))
- Serialize the cached key sets into `JWT::JWK:Set` to avoid generating OpenSSL PKeys for each time the keys are used. [#6](https://github.com/anakinj/jwk-loader/pull/6) ([@anakinj](https://github.com/anakinj))

## [1.0.0](https://github.com/anakinj/jwk-loader/compare/v0.1.0...v0.1.1) (2022-08-26)

### Fixes

- make sure 'net/http' is required [#2](https://github.com/anakinj/jwk-loader/pull/2) ([@lukad](https://github.com/lukad)).
