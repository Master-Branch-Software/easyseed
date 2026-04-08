# frozen_string_literal: true

module Easyseed
  class SequenceResetter
    def initialize(connection:)
      @connection = connection
    end

    def supported?
      postgresql? && connection.respond_to?(:reset_pk_sequence!)
    end

    def reset!
      return false unless supported?

      tables_to_reset.each do |table_name|
        connection.reset_pk_sequence!(table_name)
      end

      true
    end

    private

    attr_reader :connection

    def postgresql?
      connection.adapter_name.to_s.downcase.include?("postgres")
    end

    def tables_to_reset
      table_names.reject do |table_name|
        internal_table_names.include?(table_name) || primary_key_for(table_name).blank?
      end
    end

    def table_names
      if connection.respond_to?(:data_sources)
        connection.data_sources
      else
        connection.tables
      end
    end

    def internal_table_names
      names = %w[ar_internal_metadata schema_migrations]

      if defined?(ActiveRecord::SchemaMigration) && ActiveRecord::SchemaMigration.respond_to?(:table_name)
        names << ActiveRecord::SchemaMigration.table_name
      end

      if defined?(ActiveRecord::InternalMetadata) && ActiveRecord::InternalMetadata.respond_to?(:table_name)
        names << ActiveRecord::InternalMetadata.table_name
      end

      names.uniq
    end

    def primary_key_for(table_name)
      return "id" unless connection.respond_to?(:primary_key)

      connection.primary_key(table_name)
    end
  end
end
