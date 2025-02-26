# frozen_string_literal: true

# Module for synchronizing objects with OpenLab platform
module OpenlabSync
  extend ActiveSupport::Concern

  included do
    after_save :openlab_sync_after_save, if: :should_sync_with_openlab?
    after_destroy :openlab_destroy, if: :should_sync_with_openlab?

    def openlab_sync_after_save
      if saved_change_to_state? && published?
        # New publication - create in OpenLab
        openlab_create
      elsif published?
        # Update existing publication
        openlab_update
      end
    end

    def openlab_create
      OpenlabWorker.perform_async(:create, id)
    end

    def openlab_update
      OpenlabWorker.perform_async(:update, id)
    end

    def openlab_destroy
      OpenlabWorker.perform_async(:destroy, id)
    end

    def openlab_attributes
      OpenLabService.to_hash(self)
    end

    # Determines if the object should be synced with OpenLab
    def should_sync_with_openlab?
      openlab_sync_active? && published?
    end

    def openlab_sync_active?
      self.class.openlab_sync_active?
    end
  end

  class_methods do
    def openlab_sync_active?
      Setting.get('openlab_app_secret').present?
    end
  end
end
