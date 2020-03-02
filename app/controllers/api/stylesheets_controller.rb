# frozen_string_literal: true

# API Controller for resources of type Stylesheet
# Stylesheets are used to customize the appearance of Fab-manager
class API::StylesheetsController < API::ApiController
  caches_page :show # magic happens here

  def show
    @stylesheet = Stylesheet.find(params[:id])
    respond_to do |format|
      format.html # regular ERB template
      format.css { render text: @stylesheet.contents, content_type: 'text/css' }
    end
  end
end
