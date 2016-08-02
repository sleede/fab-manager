require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/application_helper'

class UsersExportService

  # export subscriptions
  def export_subscriptions(export)
    @subscriptions = Subscription.all.includes(:plan, :user => [:profile])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = {subscriptions: @subscriptions}
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_subscriptions.xlsx.axlsx'
    # write content to file
    File.open(export.file,"w+b") {|f| f.puts content }
  end

  # export reservations
  def export_reservations(export)
    @reservations = Reservation.all.includes(:slots, :reservable, :user => [:profile])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = {reservations: @reservations}
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_reservations.xlsx.axlsx'
    # write content to file
    File.open(export.file,"w+b") {|f| f.puts content }
  end

  # export members
  def export_members(export)
    @members = User.with_role(:member).includes(:group, :trainings, :tags, :invoices, :projects, :subscriptions => [:plan], :profile => [:address, :organization => [:address]])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = {members: @members}
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/users_members.xlsx.axlsx'
    # write content to file
    File.open(export.file,"w+b") {|f| f.puts content }
  end

end