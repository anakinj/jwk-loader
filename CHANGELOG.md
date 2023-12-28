## [Unreleased]

## [1.0.0] - 2023-12-28

- `jwk_loader/test` for convenience for testing without external dependencies. [#6](https://github.com/anakinj/jwk-loader/pull/6) ([@anakinj](https://github.com/anakinj))
- Serialize the cached key sets into `JWT::JWK:Set` to avoid generating OpenSSL PKeys for each time the keys are used. [#6](https://github.com/anakinj/jwk-loader/pull/6) ([@anakinj](https://github.com/anakinj))

## [0.1.1] - 2022-08-26

- make sure 'net/http' is required [#2](https://github.com/anakinj/jwk-loader/pull/2) ([@lukad](https://github.com/lukad)).

## [0.1.0] - 2022-07-06

- Initial release
