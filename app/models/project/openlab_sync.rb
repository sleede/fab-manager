module Project::OpenlabSync
  extend ActiveSupport::Concern

  included do
    include ActionView::Helpers::SanitizeHelper

    after_create :openlab_create, if: :openlab_sync_active?
    after_update :openlab_update, if: :openlab_sync_active?
    after_destroy :openlab_destroy, if: :openlab_sync_active?

    def openlab_create
      OpenlabWorker.delay_for(2.seconds).perform_async(:create, self.id) if self.published?
    end

    def openlab_update
      if self.published?
        if self.state_was == 'draft'
          OpenlabWorker.perform_async(:create, self.id)
        else
          OpenlabWorker.perform_async(:update, self.id)
        end
      end
    end

    def openlab_destroy
      OpenlabWorker.perform_async(:destroy, self.id)
    end

    def openlab_attributes
      {
        id: id, slug: slug, name: name, description: description, tags: tags,
        machines: machines.map(&:name),
        components: components.map(&:name),
        themes: themes.map(&:name),
        author: author&.profile&.full_name,
        collaborators: users.map { |u| u.profile.full_name },
        steps_body: steps_body,
        image_path: project_image&.attachment&.medium&.url,
        project_path: "/#!/projects/#{slug}",
        updated_at: updated_at.to_s(:iso8601),
        created_at: created_at.to_s(:iso8601),
        published_at: published_at.to_s(:iso8601)
      }
    end

    def steps_body
      concatenated_steps = project_steps.map { |s| "#{s.title} #{s.description}" }
        .join(' ').gsub('</p>', ' </p>')
        .gsub("\r\n", ' ').gsub("\n\r", ' ')
        .gsub("\n", ' ').gsub("\r", ' ').gsub("\t", ' ')

      strip_tags(concatenated_steps).strip
    end

    def openlab_sync_active?
      self.class.openlab_sync_active?
    end
  end

  class_methods do
    def openlab_sync_active?
      Rails.application.secrets.openlab_app_secret.present?
    end
  end
end
