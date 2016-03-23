class Notification < ActiveRecord::Base
  include NotifyWith::Notification

  def get_meta_data(key)
    meta_data.try(:[], key.to_s)
  end
end
