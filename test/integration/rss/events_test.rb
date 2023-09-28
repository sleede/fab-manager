# frozen_string_literal: true

require 'test_helper'
module Rss; end

class Rss::EventsTestTest < ActionDispatch::IntegrationTest
  test '#index' do
    get rss_events_path

    assert_response :success
    assert Nokogiri::XML(response.body).errors.empty?
  end
end