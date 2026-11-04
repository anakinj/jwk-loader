# Changelog

## [1.3.0](https://github.com/anakinj/jwk-loader/compare/v1.2.0...v1.3.0) (2026-11-03)


### Features

* add optional maximum JWKS cache age ([#23](https://github.com/anakinj/jwk-loader/issues/23)) ([725482e](https://github.com/anakinj/jwk-loader/commit/725482e97cfb30ddc7792eb35d9f35fb792cba2d))


### Bug Fixes

* handle absent cache entries during invalidation ([#18](https://github.com/anakinj/jwk-loader/issues/18)) ([0942d81](https://github.com/anakinj/jwk-loader/commit/0942d81b924928687e7408c85a9378ac9427af45))
* preserve cached JWKS when refreshing fails ([#17](https://github.com/anakinj/jwk-loader/issues/17)) ([cd4e68b](https://github.com/anakinj/jwk-loader/commit/cd4e68b6f4f6c01ef5aa7b1be430da4df606a0e8))
* reject unsuccessful JWKS HTTP responses ([#16](https://github.com/anakinj/jwk-loader/issues/16)) ([edf46b9](https://github.com/anakinj/jwk-loader/commit/edf46b92001c5348e51c309fa24523991b91275a))

## [1.2.0](https://github.com/anakinj/jwk-loader/compare/v1.1.0...v1.2.0) (2025-07-02)


### Features

* Allow jwt 3 ([#12](https://github.com/anakinj/jwk-loader/issues/12)) ([6c8b0f9](https://github.com/anakinj/jwk-loader/commit/6c8b0f9164b104921f1b509d2935bf61562e9d57))


### Bug Fixes

* CI for Ruby 3.5 ([#13](https://github.com/anakinj/jwk-loader/issues/13)) ([b7c0ed1](https://github.com/anakinj/jwk-loader/commit/b7c0ed1dc3f31df9464275ad681f53ee14fb794c))

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
