require 'rails_helper'

RSpec.describe NotificationCenter do
  let(:receiver1) { create :user }
  let(:receiver2) { create :user }
  let(:project) { create :project }

  it 'should respond to method .call' do
    expect(NotificationCenter).to respond_to(:call)
  end

  it 'should create a notification' do
    options = {
      type: 'notify_admin_when_project_published',
      receiver: receiver1,
      attached_object: project
    }
    NotificationCenter.call(options)
    expect(Notification.count).to eq 1
  end

  it 'should create same number of notifications with number of receiver' do
    options = {
      type: 'notify_admin_when_project_published',
      receiver: [receiver1, receiver2],
      attached_object: project
    }
    NotificationCenter.call(options)
    expect(Notification.count).to eq 2
  end
end
