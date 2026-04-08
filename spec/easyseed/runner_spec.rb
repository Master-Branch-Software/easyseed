# frozen_string_literal: true

RSpec.describe Easyseed::Runner do
  class FakeConnection
    attr_reader :events

    def initialize(adapter_name: "SQLite", tables: [])
      @adapter_name = adapter_name
      @tables = tables
      @events = []
    end

    def adapter_name
      @adapter_name
    end

    def execute(sql)
      events << "sql:#{sql}"
      EasyseedSpecLog.entries << "sql:#{sql}"
    end

    def data_sources
      @tables
    end

    def primary_key(table_name)
      return nil if table_name == "audit_logs"

      "id"
    end

    def reset_pk_sequence!(table_name)
      events << "reset:#{table_name}"
      EasyseedSpecLog.entries << "reset:#{table_name}"
    end
  end

  let(:output) { StringIO.new }
  let(:tmpdir) { Dir.mktmpdir("easyseed-runner") }
  let(:connection) { FakeConnection.new(:tables => ["widgets"]) }

  before do
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)

    stub_const("EasyseedSpecLog", Module.new)
    EasyseedSpecLog.singleton_class.attr_accessor(:entries)
    EasyseedSpecLog.entries = []
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "raises when the environment is not allowed" do
    runner = described_class.new(
      :seed_path => "db/seeds",
      :allowed_environments => %w[test development],
      :root => tmpdir,
      :environment => "production",
      :output => output
    )

    expect { runner.run! }.to raise_error(Easyseed::UnsafeEnvironmentError)
    expect(output.string).to include("Seeding only allowed in test and development environments.")
  end

  it "loads sql, csv, and ruby files in order" do
    seed_dir = File.join(tmpdir, "db", "seeds")
    FileUtils.mkdir_p(seed_dir)

    File.write(File.join(seed_dir, "01_first.sql"), "FIRST SQL")
    File.write(File.join(seed_dir, "02_second.sql"), "SECOND SQL")
    File.write(File.join(seed_dir, "widgets.csv"), "id,name\n1,Widget One\n")
    File.write(File.join(seed_dir, "01_after.rb"), "EasyseedSpecLog.entries << 'ruby:after'")

    stub_const("Widget", Class.new do
      class << self
        attr_accessor :saved_rows
      end

      self.saved_rows = []

      def initialize(attributes)
        @attributes = attributes
      end

      def save(validate: true)
        Widget.saved_rows << [@attributes, validate]
        EasyseedSpecLog.entries << "csv:#{@attributes[:name]}"
        true
      end
    end)

    runner = described_class.new(
      :seed_path => "db/seeds",
      :allowed_environments => %w[test],
      :root => tmpdir,
      :environment => "test",
      :output => output,
      :sequence_reset => false
    )

    runner.run!

    expect(EasyseedSpecLog.entries).to eq(
      ["sql:FIRST SQL", "sql:SECOND SQL", "csv:Widget One", "ruby:after"]
    )
    expect(Widget.saved_rows).to eq([[{:id => "1", :name => "Widget One"}, false]])
  end

  it "resets postgres sequences after csv files and before ruby files" do
    postgres_connection = FakeConnection.new(
      :adapter_name => "PostgreSQL",
      :tables => ["widgets", "schema_migrations", "audit_logs"]
    )
    allow(ActiveRecord::Base).to receive(:connection).and_return(postgres_connection)

    seed_dir = File.join(tmpdir, "spec", "seeds")
    FileUtils.mkdir_p(seed_dir)

    File.write(File.join(seed_dir, "widgets.csv"), "id,name\n2,Widget Two\n")
    File.write(File.join(seed_dir, "01_after.rb"), "EasyseedSpecLog.entries << 'ruby:after'")

    stub_const("Widget", Class.new do
      def initialize(attributes)
        @attributes = attributes
      end

      def save(validate: true)
        EasyseedSpecLog.entries << "csv:#{@attributes[:id]}"
        true
      end
    end)

    runner = described_class.new(
      :seed_path => "spec/seeds",
      :allowed_environments => %w[test],
      :root => tmpdir,
      :environment => "test",
      :output => output
    )

    runner.run!

    expect(EasyseedSpecLog.entries).to eq(["csv:2", "reset:widgets", "ruby:after"])
    expect(postgres_connection.events).to eq(["reset:widgets"])
  end

  it "uses Rails.root and Rails.env defaults through Easyseed.run!" do
    seed_dir = File.join(tmpdir, "db", "seeds")
    FileUtils.mkdir_p(seed_dir)
    File.write(File.join(seed_dir, "01_after.rb"), "EasyseedSpecLog.entries << 'ruby:default'")

    stub_const("Rails", double(:root => Pathname.new(tmpdir), :env => "test"))

    Easyseed.run!(
      :seed_path => "db/seeds",
      :allowed_environments => %w[test],
      :output => output,
      :sequence_reset => false
    )

    expect(EasyseedSpecLog.entries).to eq(["ruby:default"])
  end

  it "skips sequence resets when explicitly disabled" do
    postgres_connection = FakeConnection.new(:adapter_name => "PostgreSQL", :tables => ["widgets"])
    allow(ActiveRecord::Base).to receive(:connection).and_return(postgres_connection)

    seed_dir = File.join(tmpdir, "db", "seeds")
    FileUtils.mkdir_p(seed_dir)
    File.write(File.join(seed_dir, "01_after.rb"), "EasyseedSpecLog.entries << 'ruby:after'")

    runner = described_class.new(
      :seed_path => "db/seeds",
      :allowed_environments => %w[test],
      :root => tmpdir,
      :environment => "test",
      :output => output,
      :sequence_reset => false
    )

    runner.run!

    expect(postgres_connection.events).to be_empty
  end
end
