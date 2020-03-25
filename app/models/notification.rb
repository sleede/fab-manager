# frozen_string_literal: true

# Notification is an in-system alert that is shown to a specific user until it is marked as read.
class Notification < ApplicationRecord
  include NotifyWith::Notification

  def get_meta_data(key)
    meta_data.try(:[], key.to_s)
  end
end
