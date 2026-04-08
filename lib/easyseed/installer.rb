# frozen_string_literal: true

module Easyseed
  class Installer
    def initialize(root:, output: $stdout)
      @root = Pathname.new(root.to_s)
      @output = output
    end

    def install!
      FileUtils.mkdir_p(db_directory)
      FileUtils.mkdir_p(seed_directory)
      ensure_seed_directory_scaffold

      if easyseed_wrapper_installed?
        output.puts("`#{seeds_file}` already uses easyseed.")

        return :already_initialized
      end

      backup_existing_seeds_file
      write_easyseed_wrapper

      :installed
    end

    private

    attr_reader :output, :root

    def db_directory
      root.join("db")
    end

    def seeds_file
      db_directory.join("seeds.rb")
    end
    def seed_directory
      db_directory.join("seeds")
    end

    def backup_file
      db_directory.join("seeds.rb.bak")
    end

    def seed_gitkeep_file
      seed_directory.join(".gitkeep")
    end

    def seed_readme_file
      seed_directory.join("readme.txt")
    end

    def easyseed_wrapper_installed?
      File.exist?(seeds_file) && File.read(seeds_file).include?("Easyseed.run!")
    end

    def backup_existing_seeds_file
      return unless File.exist?(seeds_file)

      if File.exist?(backup_file)
        raise Error, "Backup file already exists at #{backup_file}."
      end

      FileUtils.mv(seeds_file, backup_file)
      output.puts("Moved `#{seeds_file}` to `#{backup_file}`.")
    end

    def write_easyseed_wrapper
      File.write(seeds_file, Easyseed.db_seeds_template)
      output.puts("Wrote easyseed wrapper to `#{seeds_file}`.")
    end

    def ensure_seed_directory_scaffold
      File.write(seed_gitkeep_file, "") unless File.exist?(seed_gitkeep_file)
      return if File.exist?(seed_readme_file)

      File.write(seed_readme_file, Easyseed.seed_directory_readme_template)
    end
  end
end
