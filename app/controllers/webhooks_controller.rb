class WebhooksController < ApplicationController
  
  protect_from_forgery :except => :create

  def create
    # data_json = JSON.parse request.body.read

    render nothing: true
  end
end
