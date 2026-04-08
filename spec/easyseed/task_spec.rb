# frozen_string_literal: true

RSpec.describe "easyseed:init" do
  let(:rake_application) { Rake::Application.new }
  let(:task_path) { File.expand_path("../../lib/tasks/easyseed.rake", __dir__) }

  around do |example|
    original_application = Rake.application
    Rake.application = rake_application
    load task_path
    example.run
    Rake.application = original_application
  end

  it "delegates to Easyseed.install!" do
    expect(Easyseed).to receive(:install!)

    Rake::Task["easyseed:init"].invoke
  end
end
