require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/application_helper'

class AvailabilitiesExportService

  # export all availabilities
  def export_index(export)
    @availabilities = Availability.all.includes(:machines, :trainings, :spaces, :event, :slots)

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = {availabilities: @availabilities}
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/availabilities_index.xlsx.axlsx'
    # write content to file
    File.open(export.file,"w+b") {|f| f.puts content }
  end

end