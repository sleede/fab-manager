require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'create' do
    it 'is success with user, slots and reservable'
    it 'is invalid if reservable isnt in [Training, Machine, Event]'

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

  it 'should update user credit after creation'

  it 'should create a invoice'

  it 'should can set a nb reserve places'

  it 'should can set a nb reserve reduced places'
end
