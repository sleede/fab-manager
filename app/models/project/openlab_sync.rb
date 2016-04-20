module Project::OpenlabSync
  extend ActiveSupport::Concern

  included do
    after_create :openlab_create, if: :openlab_sync_active?
    after_update :openlab_update, if: :openlab_sync_active?
    after_destroy :openlab_destroy, if: :openlab_sync_active?

    def openlab_create
      OpenlabSync.perform_async(:create, self.id) if self.published?
    end

    def openlab_update
      if self.published?
        if self.state_was == 'draft'
          OpenlabSync.perform_async(:create, self.id)
        else
          OpenlabSync.perform_async(:update, self.id)
        end
      end

    end

    def openlab_destroy
      OpenlabSync.perform_async(:destroy, self.id)
    end

    def openlab_attributes
      {
        id: id, name: name, description: description, tags: tags,
        machines: machines.map(&:name),
        components: components.map(&:name),
        themes: themes.map(&:name),
        author: author.profile.full_name,
        collaborators: users.map { |u| u.profile.full_name },
        steps_body: steps_body
      }
    end

    def steps_body
      
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
