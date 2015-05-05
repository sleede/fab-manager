class Notification < ActiveRecord::Base
  include NotifyWith::Notification
end
