# frozen_string_literal: true

require "easyseed"
require "fileutils"
require "rake"
require "stringio"
require "tmpdir"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end
end
