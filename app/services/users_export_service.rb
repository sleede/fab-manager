# frozen_string_literal: true

require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/application_helper'

# There routines will generate Excel files containing data dumped from database
class UsersExportService
  # export subscriptions
  def export_subscriptions(export)
    @subscriptions = Subscription.all.includes(:plan, statistic_profile: [user: [:profile]])

    content = ApplicationController.render(
      template: 'exports/users_subscriptions',
      locals: { subscriptions: @subscriptions },
      handlers: [:axlsx],
      formats: [:xlsx]
    )
    # write content to file
    File.binwrite(export.file, content)
  end

  # export reservations
  def export_reservations(export)
    @reservations = Reservation.all.includes(:slots, :reservable, statistic_profile: [user: [:profile]])

    content = ApplicationController.render(
      template: 'exports/users_reservations',
      locals: { reservations: @reservations },
      handlers: [:axlsx],
      formats: [:xlsx]
    )
    # write content to file
    File.binwrite(export.file, content)
  end

  # export members
  def export_members(export)
    @members = User.members
                   .includes(:group, :tags, :projects, :profile,
                             invoicing_profile: [:invoices, :address, { organization: [:address] }],
                             statistic_profile: [:trainings, { subscriptions: [:plan] }])

    content = ApplicationController.render(
      template: 'exports/users_members',
      locals: { members: @members },
      handlers: [:axlsx],
      formats: [:xlsx]
    )
    # write content to file
    File.binwrite(export.file, content)
  end
end
