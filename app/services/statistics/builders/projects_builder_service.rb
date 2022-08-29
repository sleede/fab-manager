# frozen_string_literal: true

# Generate statistics indicators about projects
class Statistics::Builders::ProjectsBuilderService
  include Statistics::Concerns::HelpersConcern
  include Statistics::Concerns::ProjectsConcern

  class << self
    def build(options = default_options)
      # project list
      Statistics::FetcherService.projects_list(options).each do |p|
        Stats::Project.create({ date: format_date(p.date),
                                type: 'project',
                                subType: 'published',
                                stat: 1 }.merge(user_info_stat(p)).merge(project_info_stat(p)))
      end
    end
  end
end
