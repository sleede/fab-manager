# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/api'
require 'minitest/mock'
require_relative 'support'

# Deliberately opt-in: these tests use real isolated Redis and Elasticsearch.
class ElasticsearchMigrationGuardTest < ActiveSupport::TestCase
  include ElasticsearchContractSupport

  setup do
    reset_search_indices
    @directory = Dir.mktmpdir('migration-guard')
    @path = File.join(@directory, 'guard.json')
    @previous = ENV.fetch('ES_MIGRATION_GUARD', nil)
    @guard = { phase: 'writes_open', run_id: 'contract', queue_prefix: 'es9-contract-',
               protected_through: '2026-11-04', reopened_at: Time.now.to_f - 10,
               target_cluster_uuid: @client.info['cluster_uuid'] }
    ENV['ES_MIGRATION_GUARD'] = @path
    save_guard
  end

  teardown do
    ENV['ES_MIGRATION_GUARD'] = @previous
    FileUtils.remove_entry(@directory) if @directory
  end

  test 'closed missing invalid or wrong cluster guards block writes while reads remain available' do
    @guard[:phase] = 'switched'
    save_guard
    assert_raises(ElasticsearchMigrationGuard::Held) { write_history }
    assert_equal 0, SearchIndex.search(family: 'machine', query: {}).total.fetch('value')
    File.unlink(@path)
    assert_raises(ElasticsearchMigrationGuard::Held) { write_history }
    File.write(@path, '{broken')
    assert_raises(ElasticsearchMigrationGuard::Held) { write_history }
    @guard.merge!(phase: 'writes_open', target_cluster_uuid: 'another-cluster')
    save_guard
    assert_raises(ElasticsearchMigrationGuard::Held) { write_history }
  end

  test 'historical cleaners are blocked while current work and identity based updates are allowed' do
    write_history
    SearchIndex.update_stat(family: 'machine', id: 'same-id', changes: { ca: 19.95 })
    assert_equal 19.95, @client.get(**SearchIndex.target('machine'), id: 'same-id').dig('_source', 'ca')
    assert_raises(ElasticsearchMigrationGuard::Held) do
      Statistics::CleanerService.clean_stat(start_date: '20190101', end_date: '20261104')
    end
    Statistics::CleanerService.clean_stat(start_date: '20261105', end_date: '20261105')
    assert @client.exists?(**SearchIndex.target('machine'), id: 'same-id')
    SearchIndex.delete(family: 'project', id: 'same-id')
    assert @client.exists?(**SearchIndex.target('machine'), id: 'same-id')
    assert_not @client.exists?(**SearchIndex.target('project'), id: 'same-id')
  end

  test 'actual Sidekiq normalization keeps legacy queue and prefixes only newly created work' do
    Sidekiq::Testing.disable! do
      old = { 'class' => 'PeriodStatisticsWorker', 'args' => [3000], 'queue' => 'migration-old', 'created_at' => 1 }
      old_jid = Sidekiq::Client.push(old)
      new_jid = Sidekiq::Client.push('class' => 'PeriodStatisticsWorker', 'args' => [3001], 'queue' => 'migration-new')
      assert Sidekiq::Queue.new('migration-old').find_job(old_jid)
      new_job = Sidekiq::Queue.new('es9-contract-migration-new').find_job(new_jid)
      assert new_job
      assert_operator new_job.item.fetch('created_at'), :>=, @guard[:reopened_at]
      assert_raises(ElasticsearchMigrationGuard::Held) do
        ElasticsearchMigrationGuard::ServerMiddleware.new.call(nil, old, 'migration-old') { flunk 'Old job executed' }
      end
      assert_equal %w[es9-contract-migration-old es9-contract-migration-new],
                   ElasticsearchMigrationGuard.worker_queues!(%w[migration-old es9-contract-migration-new])
      ran = false
      ElasticsearchMigrationGuard::ServerMiddleware.new.call(nil, new_job.item, new_job.queue) { ran = true }
      assert ran
      assert Sidekiq::Queue.new('migration-old').find_job(old_jid), 'Old queued payload must remain intact'
    ensure
      # Only this test's exact JIDs; never purge a queue or scheduled/retry sets.
      Sidekiq::Queue.new('migration-old').find_job(old_jid)&.delete if old_jid
      Sidekiq::Queue.new('es9-contract-migration-new').find_job(new_jid)&.delete if new_jid
    end
  end

  private

  def save_guard
    File.write(@path, JSON.generate(@guard))
  end

  def write_history
    %w[machine project].each do |family|
      SearchIndex.index_document(family: family, id: 'same-id', source: { type: 'booking', date: '2019-01-01', stat: 0, ca: 0 })
    end
  end
end
