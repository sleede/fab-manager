# frozen_string_literal: true

require 'test_helper'

# Pure guard rules; no Elasticsearch or Sidekiq process required.
class ElasticsearchMigrationGuardWorkerQueuesTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir('migration-guard')
    @path = File.join(@directory, 'guard.json')
    @previous = ENV.fetch('ES_MIGRATION_GUARD', nil)
    @guard = { phase: 'writes_open', run_id: 'unit', queue_prefix: 'es9-unit-', protected_through: '2026-11-05', reopened_at: 1 }
  end

  teardown do
    ENV['ES_MIGRATION_GUARD'] = @previous
    FileUtils.remove_entry(@directory)
  end

  test 'without a migration guard the configured queues are unchanged' do
    ENV['ES_MIGRATION_GUARD'] = nil
    assert_equal %w[stripe default], ElasticsearchMigrationGuard.worker_queues!(%w[stripe default])
  end

  test 'after reopening every configured queue and weight is mapped onto the new namespace only' do
    save_guard
    configured = %w[stripe stripe default es9-unit-mailers]
    assert_equal %w[es9-unit-stripe es9-unit-stripe es9-unit-default es9-unit-mailers],
                 ElasticsearchMigrationGuard.worker_queues!(configured)
  end

  test 'workers stay held before reopening or without queues' do
    @guard[:phase] = 'switched'
    save_guard
    assert_raises(ElasticsearchMigrationGuard::Held) { ElasticsearchMigrationGuard.worker_queues!(%w[default]) }
    @guard[:phase] = 'writes_open'
    save_guard
    assert_raises(ElasticsearchMigrationGuard::Held) { ElasticsearchMigrationGuard.worker_queues!([]) }
    File.unlink(@path)
    assert_raises(ElasticsearchMigrationGuard::Held) { ElasticsearchMigrationGuard.worker_queues!(%w[default]) }
  end

  private

  def save_guard
    File.write(@path, JSON.generate(@guard))
    ENV['ES_MIGRATION_GUARD'] = @path
  end
end
