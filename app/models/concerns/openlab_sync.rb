# frozen_string_literal: false

# module definition
module OpenlabSync
  extend ActiveSupport::Concern

  included do
    after_create :openlab_create, if: :openlab_sync_active?
    run_after_update :openlab_update, if: :openlab_sync_active?
    after_destroy :openlab_destroy, if: :openlab_sync_active?

    def openlab_create
      OpenlabWorker.perform_in(2.seconds, :create, id) if published?
    end

    def openlab_update
      return unless published?

      if state_was == 'draft'
        OpenlabWorker.perform_async(:create, id)
      else
        OpenlabWorker.perform_async(:update, id)
      end
    end

    def openlab_destroy
      OpenlabWorker.perform_async(:destroy, id)
    end

    def openlab_attributes
      OpenLabService.to_hash(self)
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
