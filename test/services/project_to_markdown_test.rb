# frozen_string_literal: true

require 'test_helper'

class ProjectToMarkdownTest < ActiveSupport::TestCase
  test "ProjectToMarkdown is working" do
    project = projects(:project_1)
    service = ProjectToMarkdown.new(project)

    markdown_str = nil

    assert_nothing_raised do
      markdown_str = service.call
    end

    assert_includes markdown_str, project.name
    project.project_steps.each do |project_step|
      assert_includes markdown_str, project_step.title
    end
  end
end
