require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'create' do
    it 'is success with user, plan'

    it 'is success with a subscription'

    context 'stripe' do
      it 'should payment success'
      it 'is invalid if payment info invalid'
    end

    context 'satori' do
      it 'should success'
      it 'is invalid if payment info invalid'
    end
  end

  it 'should reset user credit after creation'

  it 'should set a expired at after creation'

  it 'should create a invoice'

end
