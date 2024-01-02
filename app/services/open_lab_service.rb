# frozen_string_literal: true

# Provides methods to sync projects on OpenLab
class OpenLabService
  class << self
    def to_hash(project)
      {
        id: project.id,
        slug: project.slug,
        name: project.name,
        description: project.description,
        tags: project.tags,
        machines: project.machines.map(&:name),
        components: project.components.map(&:name),
        themes: project.themes.map(&:name),
        author: project.author&.user&.profile&.full_name,
        collaborators: project.users.map { |u| u&.profile&.full_name },
        steps_body: steps_body(project),
        image_path: project.project_image&.attachment&.medium&.url,
        project_path: "/#!/projects/#{project.slug}",
        updated_at: project.updated_at.to_fs(:iso8601),
        created_at: project.created_at.to_fs(:iso8601),
        published_at: project.published_at.to_fs(:iso8601)
      }
    end

    def steps_body(project)
      concatenated_steps = project.project_steps.map { |s| "#{s.title} #{s.description}" }
                                  .join(' ').gsub('</p>', ' </p>')
                                  .gsub("\r\n", ' ').gsub("\n\r", ' ')
                                  .gsub("\n", ' ').gsub("\r", ' ').gsub("\t", ' ')

      ActionController::Base.helpers.strip_tags(concatenated_steps).strip
    end
  end
end
