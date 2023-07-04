# frozen_string_literal: true

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test 'fixtures are valid' do
    Project.find_each do |project|
      assert project.valid?
    end
  end

  test 'relation project_categories' do
    assert_equal [project_categories(:project_category_1)], projects(:project_1).project_categories
  end
end
