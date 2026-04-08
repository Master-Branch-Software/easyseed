# frozen_string_literal: true

require "active_record"
require "active_support/core_ext/array/conversions"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "fileutils"
require "pathname"

require_relative "easyseed/installer"
require_relative "easyseed/railtie" if defined?(Rails::Railtie)
require_relative "easyseed/runner"
require_relative "easyseed/sequence_resetter"
require_relative "easyseed/version"

module Easyseed
  class Error < StandardError; end
  class UnsafeEnvironmentError < Error; end

  def self.run!(**options)
    Runner.new(**options).run!
  end

  def self.install!(root: default_root, output: $stdout)
    Installer.new(:root => root, :output => output).install!
  end

  def self.db_seeds_template
    <<~RUBY
      require "easyseed"

      Easyseed.run!(
        :seed_path => "db/seeds",
        :allowed_environments => %w[test development]
      )
    RUBY
  end
  def self.seed_directory_readme_template
    <<~TEXT
      Put SQL, CSV, and Ruby seed files in this directory.

      Load order is:
      1. *.sql
      2. *.csv
      3. *.rb

      Within each file type, files are loaded in sorted filename order.
      If some files must run in a specific order, prefix them accordingly,
      for example:

      001_z.csv
      002_a.csv

      The wrapper in db/seeds.rb calls Easyseed.run! against this directory.
    TEXT
  end

  def self.default_root
    return Rails.root if defined?(Rails) && Rails.respond_to?(:root)

    Pathname.pwd
  end

  def self.default_environment
    return Rails.env.to_s if defined?(Rails) && Rails.respond_to?(:env)

    ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
  end
end
