# frozen_string_literal: true

# send a notification if child age > 18 years ago
class ChildAgeWorker
  include Sidekiq::Worker

  def perform
    children = Child.where('birthday = ?', 18.years.ago + 2.days)
    children.each do |child|
      NotificationCenter.call type: 'notify_user_when_child_age_will_be_18',
                              receiver: child.user,
                              attached_object: child
    end
  end
end
