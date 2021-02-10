# frozen_string_literal: true

require 'minitest/autorun'
require 'hstore_translate'

require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

I18n.available_locales = %i[en fr]

class Post < ActiveRecord::Base
  translates :title, :body_1
end

class PostDetailed < Post
  translates :comment, allow_blank: true
end

module HstoreTranslate
  class Test < Minitest::Test
    class << self
      def prepare_database
        create_database
        create_table
      end

      private

      def db_config
        @db_config ||= begin
          filepath = File.join('test', 'database.yml')
          YAML.load_file(filepath)['test']
        end
      end

      def establish_connection(config)
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection
      end

      def create_database
        connection = establish_connection(db_config)

        begin
          connection.create_database(db_config['database'])
        rescue StandardError
          nil
        end

        enable_extension
      end

      def enable_extension
        connection = establish_connection(db_config)
        return if connection.select_value("SELECT proname FROM pg_proc WHERE proname = 'akeys'")

        if connection.send(:postgresql_version) < 90_100
          pg_sharedir = `pg_config --sharedir`.strip
          hstore_script_path = File.join(pg_sharedir, 'contrib', 'hstore.sql')
          connection.execute(File.read(hstore_script_path))
        else
          connection.execute('CREATE EXTENSION IF NOT EXISTS hstore')
        end
      end

      def create_table
        connection = establish_connection(db_config)
        connection.create_table(:posts, force: true) do |t|
          t.column :title_translations, 'hstore'
          t.column :body_1_translations, 'hstore'
          t.column :comment_translations, 'hstore'
        end
      end
    end

    prepare_database

    def setup
      I18n.available_locales = %w[en en-US fr]
      I18n.config.enforce_available_locales = true
      DatabaseCleaner.start
    end

    def teardown
      DatabaseCleaner.clean
    end
  end
end
