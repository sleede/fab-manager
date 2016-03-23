class ProjectUser < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :project
  belongs_to :user

  before_create :generate_valid_token
  after_commit :notify_project_collaborator_to_valid, on: :create
  after_update :notify_project_author_when_collaborator_valid, if: :is_valid_changed?

  private
  def generate_valid_token
    begin
      self.valid_token = SecureRandom.hex
    end while self.class.exists?(valid_token: valid_token)
  end

  def notify_project_collaborator_to_valid
    NotificationCenter.call type: 'notify_project_collaborator_to_valid',
                            receiver: user,
                            attached_object: self
  end

  def notify_project_author_when_collaborator_valid
    NotificationCenter.call type: 'notify_project_author_when_collaborator_valid',
                            receiver: project.author,
                            attached_object: self
  end
end
