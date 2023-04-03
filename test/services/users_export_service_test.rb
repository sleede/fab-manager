# frozen_string_literal: true

require 'test_helper'

class UsersExportServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.admins.first
  end

  test 'export reservations' do
    export = Export.new(category: 'users', export_type: 'reservations', user: @user)
    assert export.save, 'unable to save reservations export'
    UsersExportWorker.new.perform(export.id)

    assert File.exist?(export.file), 'Export XLSX was not generated'

    File.delete(export.file)
  end

  test 'export subscriptions' do
    export = Export.new(category: 'users', export_type: 'subscriptions', user: @user)
    assert export.save, 'unable to save subscriptions export'
    UsersExportWorker.new.perform(export.id)

    assert File.exist?(export.file), 'Export XLSX was not generated'

    File.delete(export.file)
  end

  test 'export members' do
    export = Export.new(category: 'users', export_type: 'members', user: @user)
    assert export.save, 'unable to save members export'
    UsersExportWorker.new.perform(export.id)

    assert File.exist?(export.file), 'Export XLSX was not generated'

    File.delete(export.file)
  end
end
