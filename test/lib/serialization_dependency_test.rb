# frozen_string_literal: true

require 'test_helper'
require 'msgpack'
require 'oj'
require 'bootsnap/load_path_cache/store'

class SerializationDependencyTest < ActiveSupport::TestCase
  setup do
    @fixtures = Rails.root.join('test/fixtures/files/dependencies')
    @payload = JSON.parse(File.read(@fixtures.join('legacy_payload.json')))
  end

  test 'MessagePack reads bytes produced by the previous version' do
    assert_equal @payload, MessagePack.unpack(File.binread(@fixtures.join('legacy_messagepack.bin')))
    assert_equal @payload, MessagePack.unpack(MessagePack.pack(@payload))
  end

  test 'MessagePack preserves binary strings integer boundaries and nested values' do
    value = { 'binary' => "\x00\xFF".b, 'signed' => -(2**63), 'unsigned' => (2**64) - 1,
              'nested' => [nil, true, false, { 'value' => 'Montréal' }] }
    decoded = MessagePack.unpack(MessagePack.pack(value))
    assert_equal value, decoded
    assert_equal Encoding::BINARY, decoded.fetch('binary').encoding
  end

  test 'MessagePack buffers can be cleared and reused with bounded data' do
    buffer = MessagePack::Buffer.new
    16.times do |index|
      bytes = "synthetic-#{index}".b
      buffer.write(bytes)
      assert_equal bytes, buffer.to_s
      buffer.clear
      assert_equal 0, buffer.size
    end
  end

  test 'Oj reads legacy compatible JSON without changing global serializer options' do
    options = Oj.default_options.dup
    source = File.read(@fixtures.join('legacy_oj_compat.json'))
    assert_equal @payload, Oj.load(source, mode: :strict)
    assert_equal @payload, Oj.load(Oj.dump(@payload, mode: :compat), mode: :strict)
    assert_equal options, Oj.default_options
  end

  test 'actual Rails JSON date decimal and Unicode representations remain compatible' do
    value = { amount: BigDecimal('19.95'), at: Time.utc(2026, 10, 31, 8), name: 'Montréal' }
    json = ActiveSupport::JSON.encode(value)
    expected = { 'amount' => '19.95', 'at' => '2026-10-31T08:00:00.000Z', 'name' => 'Montréal' }
    assert_equal expected, JSON.parse(json)
    assert_equal expected, Oj.load(json, mode: :strict)
  end

  test 'bounded malformed JSON and MessagePack values are rejected' do
    assert_raises(Oj::ParseError) { Oj.load('{"broken":[}', mode: :strict) }
    assert_raises(MessagePack::MalformedFormatError) { MessagePack.unpack("\xC1".b) }
  end

  test 'the real Bootsnap store reads old cache bytes or invalidates other Ruby platforms' do
    path = @fixtures.join('legacy_bootsnap_store.bin')
    data = MessagePack.unpack(File.binread(path))
    store = Bootsnap::LoadPathCache::Store.new(path.to_s, readonly: true)
    if data[Bootsnap::LoadPathCache::Store::VERSION_KEY] == Bootsnap::LoadPathCache::Store::CURRENT_VERSION
      assert_equal @payload, store.get('synthetic-key')
    else
      assert_nil store.get('synthetic-key')
    end
  end

  test 'trusted legacy Rails cache entries retain values in a memory cache' do
    # This fixture is locally generated and repository-owned, never untrusted member input.
    bytes = File.binread(@fixtures.join('legacy_cache_entry.bin'))
    entry = ActiveSupport::Cache::Coders[ActiveSupport::Cache.format_version].load(bytes)
    assert_equal @payload, entry.value
    cache = ActiveSupport::Cache::MemoryStore.new
    assert cache.write('synthetic-key', entry.value)
    assert_equal @payload, cache.read('synthetic-key')
    cache.delete('synthetic-key')
    assert_nil cache.read('synthetic-key')
  end

  test 'Sidekiq JSON reads legacy arguments and preserves newly enqueued job arguments' do
    assert_equal @payload, Sidekiq.load_json(File.read(@fixtures.join('legacy_sidekiq.json')))
    assert_equal @payload, Sidekiq.load_json(Sidekiq.dump_json(@payload))
    previous = StatisticsExportWorker.jobs.length
    StatisticsExportWorker.perform_async(7)
    assert_equal [7], StatisticsExportWorker.jobs.last.fetch('args')
    assert_equal previous + 1, StatisticsExportWorker.jobs.length
  ensure
    StatisticsExportWorker.jobs.slice!(previous..) if previous
  end
end

class SerializationApiDependencyTest < ActionDispatch::IntegrationTest
  test 'public API responses retain their JSON schema with the installed serializers' do
    get '/api/machines'
    assert_response :success
    assert_equal 'application/json', response.media_type
    machines = JSON.parse(response.body)
    assert_kind_of Array, machines
    assert_not_empty machines
    assert_kind_of Integer, machines.first.fetch('id')
    assert_kind_of String, machines.first.fetch('name')
  end

  test 'authenticated member JSON retains its identifier' do
    login_as(users(:user2), scope: :user)
    get '/api/members/current'
    assert_response :success
    assert_equal users(:user2).id, JSON.parse(response.body).fetch('id')
  ensure
    Warden.test_reset!
  end
end
