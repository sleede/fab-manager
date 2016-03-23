require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { build :user }

  describe 'create' do
    it 'is success if user email, gender, first name, last name, group, birthday and phone are presents' do
      expect(user.save).to be true
    end

    it 'is invalid when email is empty' do
      user.email = nil
      expect(user).to be_invalid
    end

    it 'is invalid when email format invalid' do
      user.email = 'this a invalid email'
      expect(user).to be_invalid
    end

    it 'is invalid when first name is empty' do
      user.profile.first_name = nil
      expect(user).to be_invalid
    end

    it 'is invalid when last name is empty' do
      user.profile.last_name = nil
      expect(user).to be_invalid
    end

    it 'is invalid when birthday is empty' do
      user.profile.birthday = nil
      expect(user).to be_invalid
    end

    it 'is invalid when phone is empty or not numerical' do
      user.profile.phone = nil
      expect(user).to be_invalid
      user.profile.phone = "phone"
      expect(user).to be_invalid
    end

    it 'is invalid when group is empty' do
      user.group = nil
      expect(user).to be_invalid
    end

    it 'is invalid when group is empty' do
      user.group = nil
      expect(user).to be_invalid
    end

    it 'is invalid when dont accept cgu' do
      user.cgu = '0'
      expect(user).to be_invalid
      expect(user.errors[:cgu]).to include(I18n.t('activerecord.errors.messages.empty'))
    end
  end

  context 'after creation' do
    it 'has a member role' do
      member = create(:user)
      expect(member.is_member?).to be true
    end

    it 'create a stripe customer' do
      member = create(:user)
      allow(member).to receive(:create_stripe_customer) { |u| member.stp_customer_id = 'stripe customer id' }
      member.run_callbacks(:commit)
      expect(member.stp_customer_id).to eq 'stripe customer id'
    end
  end
end

