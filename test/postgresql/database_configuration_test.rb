# frozen_string_literal: true

require 'minitest/autorun'
require 'erb'
require 'yaml'
require 'json'
require 'tempfile'
require 'active_support/core_ext/enumerable'

# These tests render the real templates without opening any database connection.
class PostgresqlDatabaseConfigurationTest < Minitest::Test
  KEYS = %w[POSTGRES_HOST POSTGRES_USERNAME POSTGRES_PASSWORD POSTGRES_PASSWORD_FILE POSTGRES_DB POSTGRES_TEST_DB].freeze

  def setup
    @saved = KEYS.index_with { |key| ENV.fetch(key, nil) }
    KEYS.each { |key| ENV.delete(key) }
  end

  def teardown
    @saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def render(relative)
    path = File.expand_path("../../#{relative}", __dir__)
    YAML.safe_load(ERB.new(File.read(path)).result, aliases: true)
  end

  def test_legacy_development_defaults
    config = render('config/database.yml.default')['development']
    assert_equal 'fabmanager-postgres', config['host']
    assert_equal 'postgres', config['username']
    assert_equal 'postgres', config['password']
  end

  def test_yaml_characters_are_preserved
    ['#prefix', '@prefix', 'colon: value', "quote\" and apostrophe'", "two\nlines"].each do |password|
      ENV['POSTGRES_PASSWORD'] = password
      assert_equal password, render('config/database.yml.default')['test']['password']
      assert_equal password, render('docker/database.yml')['production']['password']
    end
  end

  def test_file_secret_takes_precedence
    Tempfile.create('synthetic-password') do |file|
      file.write("file: secret#value\n")
      file.flush
      ENV['POSTGRES_PASSWORD_FILE'] = file.path
      ENV['POSTGRES_PASSWORD'] = 'unused synthetic value'
      assert_equal 'file: secret#value', render('docker/database.yml')['production']['password']
      assert_equal 'file: secret#value', render('config/database.yml.default')['test']['password']
    end
  end

  def test_missing_file_does_not_fall_back_to_an_empty_password
    ENV['POSTGRES_PASSWORD_FILE'] = '/nonexistent/fm-pg-b-password'
    assert_raises(Errno::ENOENT) { render('docker/database.yml') }
  end

  def test_database_is_explicit_and_quoted
    ENV['POSTGRES_DB'] = 'synthetic: db'
    %w[development production staging].each do |environment|
      assert_equal 'synthetic: db', render('docker/database.yml')[environment]['database']
    end
    assert_equal 'synthetic: db', render('config/database.yml.default')['development']['database']
  end

  # The test database is erased by the test tasks: it must never follow the application database
  def test_test_database_ignores_the_application_database
    ENV['POSTGRES_DB'] = 'fablab_production'
    assert_equal 'fablab_test', render('docker/database.yml')['test']['database']
    assert_equal 'fabmanager_test', render('config/database.yml.default')['test']['database']
    ENV['POSTGRES_TEST_DB'] = 'synthetic: test db'
    assert_equal 'synthetic: test db', render('docker/database.yml')['test']['database']
    assert_equal 'synthetic: test db', render('config/database.yml.default')['test']['database']
  end
end
