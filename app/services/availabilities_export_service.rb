# frozen_string_literal: true

require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/application_helper'

# Retrieve all availabilities and their related objects and write the result as a table in an excel file
class AvailabilitiesExportService
  # export all availabilities
  def export_index(export)
    @availabilities = Availability.all.includes(:machines, :trainings, :spaces, :event, :slots)

    content = ApplicationController.render(
      template: 'exports/availabilities_index',
      locals: { availabilities: @availabilities },
      handlers: [:axlsx],
      formats: [:xlsx]
    )
    # write content to file
    File.binwrite(export.file, content)
  end
end
