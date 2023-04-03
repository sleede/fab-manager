# frozen_string_literal: true

# API Controller for resources of type Stylesheet
# Stylesheets are used to customize the appearance of Fab-manager
class API::StylesheetsController < API::APIController
  def show
    @stylesheet = Stylesheet.find(params[:id])
  end
end
