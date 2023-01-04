# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'
require 'sidekiq/testing'

class AccountingWorkerTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.inline!
    @worker = AccountingWorker.new
  end

  test 'build accounting lines for yesterday by default' do
    date = DateTime.current.midnight
    travel_to(date)
    @worker.perform
    assert_match(/^yesterday:/, @worker.performed)
    assert_match(date.yesterday.to_date.iso8601, @worker.performed)
  end

  test 'build accounting lines for today' do
    @worker.perform(:today)
    assert_match(/^today:/, @worker.performed)
    assert_match(DateTime.current.to_date.iso8601, @worker.performed)
  end

  test 'build specified invoices selection' do
    ids = [5820, 5821, 5822]
    @worker.perform(:invoices, ids)
    assert_match(/^invoices:/, @worker.performed)
    assert_match(ids.to_s, @worker.performed)
  end

  test 'build all invoices' do
    @worker.perform(:all)
    assert_match(/^all:/, @worker.performed)
    assert_match(Invoice.all.map(&:id).to_s, @worker.performed)
  end
end
