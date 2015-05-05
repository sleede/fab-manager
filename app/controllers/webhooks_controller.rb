class WebhooksController < ApplicationController
  def create
    # data_json = JSON.parse request.body.read

    render nothing: true
  end
end
