# frozen_string_literal: true

require 'test_helper'
module Rss; end

class Rss::ProjectsTestTest < ActionDispatch::IntegrationTest
  test '#index' do
    get rss_projects_path

    assert_response :success
    assert Nokogiri::XML(response.body).errors.empty?
  end
end