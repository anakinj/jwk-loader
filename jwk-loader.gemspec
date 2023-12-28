# frozen_string_literal: true

require_relative "lib/jwk_loader/version"

Gem::Specification.new do |spec|
  spec.name = "jwk-loader"
  spec.version = JwkLoader::VERSION
  spec.authors = ["Joakim Antman"]
  spec.email = ["antmanj@gmail.com"]

  spec.summary = "Tooling for handling JWK loading, parsing and caching"
  # spec.description = "Tooling for handling JWK loading, parsing and caching"
  spec.homepage = "https://github.com/anakinj/jwk-loader"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/anakinj/jwk-loader/blob/#{JwkLoader::VERSION}/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "jwt", "~> 2.6"
end
