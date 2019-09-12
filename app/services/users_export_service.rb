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

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = { subscriptions: @subscriptions }
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_subscriptions.xlsx.axlsx'
    # write content to file
    File.open(export.file, 'w+b') { |f| f.puts content }
  end

  # export reservations
  def export_reservations(export)
    @reservations = Reservation.all.includes(:slots, :reservable, :invoice, statistic_profile: [user: [:profile]])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = { reservations: @reservations }
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_reservations.xlsx.axlsx'
    # write content to file
    File.open(export.file, 'w+b') { |f| f.puts content }
  end

  # export members
  def export_members(export)
    @members = User.with_role(:member)
                   .includes(:group, :tags, :projects, :profile,
                             invoicing_profile: [:invoices, :address, organization: [:address]],
                             statistic_profile: [:trainings, subscriptions: [:plan]])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = { members: @members }
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_members.xlsx.axlsx'
    # write content to file
    File.open(export.file, 'w+b') { |f| f.puts content }
  end

end
