# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../../config/environment'
require 'minitest/autorun'
require 'tempfile'

class PostgreSQLDatabaseTasksTest < Minitest::Test
  FakeConnection = Struct.new(:schema_search_path)

  def setup
    @db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      'test',
      'primary',
      adapter: 'postgresql',
      database: 'fabmanager_test'
    )
    @tasks = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(@db_config)
  end

  def test_structure_load_strips_unsupported_transaction_timeout_setting_before_invoking_psql
    structure_file = Tempfile.new(['structure', '.sql'])
    structure_file.write("SET statement_timeout = 0;\nSET transaction_timeout = 0;\nCREATE TABLE example (id bigint);\n")
    structure_file.flush

    captured_file = nil
    captured_contents = nil
    @tasks.singleton_class.define_method(:run_cmd) do |_cmd, args, _action|
      captured_file = args[args.index('--file') + 1]
      captured_contents = File.read(captured_file)
    end

    @tasks.structure_load(structure_file.path, nil)

    assert captured_file
    assert_operator structure_file.path, :!=, captured_file
    assert_includes captured_contents, 'SET statement_timeout = 0;'
    assert captured_contents.exclude?('SET transaction_timeout = 0;')
    assert_includes File.read(structure_file.path), 'SET transaction_timeout = 0;'
  ensure
    structure_file&.close!
  end

  def test_structure_dump_removes_unsupported_transaction_timeout_setting_from_dumped_file
    structure_file = Tempfile.new(['structure', '.sql'])

    @tasks.singleton_class.define_method(:run_cmd) do |_cmd, args, _action|
      File.write(
        args[args.index('--file') + 1],
        "SET statement_timeout = 0;\nSET transaction_timeout = 0;\nCREATE TABLE example (id bigint);\n"
      )
    end
    @tasks.singleton_class.define_method(:remove_sql_header_comments) { |_filename| true }
    @tasks.singleton_class.define_method(:connection) { FakeConnection.new('public') }

    @tasks.structure_dump(structure_file.path, nil)

    assert_includes File.read(structure_file.path), 'SET statement_timeout = 0;'
    assert File.read(structure_file.path).exclude?('SET transaction_timeout = 0;')
  ensure
    structure_file&.close!
  end
end
