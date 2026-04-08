# frozen_string_literal: true

require "csv"

module Easyseed
  class Runner
    DEFAULT_ALLOWED_ENVIRONMENTS = %w[test development].freeze

    def initialize(seed_path:, allowed_environments: DEFAULT_ALLOWED_ENVIRONMENTS, root: Easyseed.default_root, environment: Easyseed.default_environment, output: $stdout, sequence_reset: :auto)
      @seed_path = seed_path
      @allowed_environments = Array(allowed_environments).map(&:to_s)
      @root = Pathname.new(root.to_s)
      @environment = environment.to_s
      @output = output
      @sequence_reset = sequence_reset
    end

    def run!
      start_time = Time.now

      ensure_allowed_environment!

      print_feedback("Bulk loading seed files from #{seed_directory} (#{environment} environment)", :banner_char => "#")

      print_feedback("Loading seeds...") do
        load_sql_files
        load_csv_files
        reset_sequences_if_needed
        load_ruby_files
      end

      output.puts("Database seeded in: #{Time.now - start_time} seconds.")

      true
    end

    private

    attr_reader :allowed_environments, :environment, :output, :root, :seed_path, :sequence_reset

    def seed_directory
      @seed_directory ||= begin
        path = Pathname.new(seed_path.to_s)
        path.absolute? ? path : root.join(path)
      end
    end

    def ensure_allowed_environment!
      return if allowed_environments.include?(environment)

      print_feedback("Seeding only allowed in #{allowed_environments.to_sentence} environments.", :banner_char => "!")

      raise UnsafeEnvironmentError, "Seeding not allowed in #{environment} environment."
    end

    def load_sql_files
      sql_files = files_for("*.sql")

      print_section_heading("Loading SQL seeds", sql_files)

      sql_files.each do |sql_file|
        output.puts("#{File.basename(sql_file)}...")
        connection.execute(File.read(sql_file).strip)
      end
    end

    def load_csv_files
      csv_files = files_for("*.csv")

      print_section_heading("Loading CSV seeds", csv_files)

      csv_files.each do |csv_file|
        output.puts("#{File.basename(csv_file)}...")

        model_class = File.basename(csv_file, ".*").classify.constantize

        CSV.foreach(csv_file, :headers => true, :header_converters => :symbol) do |row|
          attributes = row.headers.each_with_object({}) do |header, memo|
            memo[header] = row[header]
          end

          model_class.new(attributes).save(:validate => false)
        end
      end
    end

    def reset_sequences_if_needed
      return unless reset_sequences?

      sequence_resetter = SequenceResetter.new(:connection => connection)
      return unless sequence_resetter.supported?

      print_section_heading("Resetting PostgreSQL sequences", [true])
      sequence_resetter.reset!
    end

    def load_ruby_files
      ruby_files = files_for("*.rb")

      print_section_heading("Loading Ruby script seeds", ruby_files)

      ruby_files.each do |ruby_file|
        output.puts("#{File.basename(ruby_file)}...")
        load ruby_file
      end
    end

    def files_for(pattern)
      Dir[seed_directory.join(pattern).to_s].sort
    end

    def print_section_heading(message, collection)
      return unless collection.any?

      output.puts
      output.puts(message.upcase)
    end

    def print_feedback(message = "", options = {})
      banner_char = options.fetch(:banner_char, "-")
      banner = (banner_char * 80)[0..79]

      output.puts(banner)
      message.empty? ? output.puts : output.puts("#{message}\n")

      if block_given?
        yield
        output.puts("\n...done.")
      end

      output.puts("#{banner}\n\n")
    end

    def reset_sequences?
      case sequence_reset
      when false
        false
      when true
        true
      else
        connection.adapter_name.to_s.downcase.include?("postgres")
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
