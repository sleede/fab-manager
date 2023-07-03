# frozen_string_literal: true

require 'test_helper'

class ProjectCategoryTest < ActiveSupport::TestCase
  test 'fixtures are valid' do
    ProjectCategory.find_each do |project_category|
      assert project_category.valid?
    end
  end
end
