# frozen_string_literal: true

require_relative "lib/easyseed/version"

Gem::Specification.new do |spec|
  spec.name = "easyseed"
  spec.version = Easyseed::VERSION
  spec.summary = "Rails-friendly database seed runner for SQL, CSV, and Ruby seeds."
  spec.description = "Extracts reusable Rails database seeding behavior with environment guards, file loading, PostgreSQL sequence resets, and a simple installer task."
  spec.authors = ["Ray Parker"]
  spec.email = ["rayparkerbassplayer@gmail.com"]
  spec.files = Dir.chdir(__dir__) do
    Dir[".rspec", "Gemfile", "README.md", "Rakefile", "lib/**/*.rb", "lib/tasks/**/*.rake", "spec/**/*.rb"]
  end
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.7"
  spec.license = "MIT"

  spec.add_dependency "activerecord", ">= 6.1", "< 8.1"
  spec.add_dependency "activesupport", ">= 6.1", "< 8.1"
  spec.add_dependency "csv", ">= 3.2"
  spec.add_dependency "railties", ">= 6.1", "< 8.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
