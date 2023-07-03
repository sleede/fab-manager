# frozen_string_literal: true

require 'test_helper'

class ProjectsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'download markdown file' do
    get "/api/projects/1/markdown"

    assert_response :success
    assert_equal "text/markdown", response.content_type
  end
end