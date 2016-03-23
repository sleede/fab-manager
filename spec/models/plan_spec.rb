require 'rails_helper'

RSpec.describe Plan, type: :model do
  let(:group){ Group.new(name: 'groupe test', slug: SecureRandom.hex) }

  describe 'validations' do
    it 'is success with amount and group' do
      plan = Plan.new(amount: 500, group: group)
      expect(plan).to be_valid
    end

    it 'is invalid without amount' do
      plan = Plan.new(group: group)
      expect(plan).to be_invalid
    end

    it 'is invalid without group' do
      plan = Plan.new(amount: 500)
      expect(plan).to be_invalid
    end
  end

  context "on creation" do
    before :each do
      @plan_id = SecureRandom.hex
      @plan_name = SecureRandom.hex
      allow(Stripe::Plan).to receive(:create).and_return(double(id: @plan_id, name: @plan_name))
    end

    it 'calls Stripe::Plan create method' do
      plan = Plan.create(amount: 500, interval: 'month', group: group)
      expect(Stripe::Plan).to have_received :create
    end

    it 'saves stripe_plan.id' do
      plan = Plan.create(amount: 500, interval: 'month', group: group)
      expect(plan.stp_plan_id).to eq(@plan_id)
    end

    it 'saves stripe_plan.name' do
      plan = Plan.create(amount: 500, interval: 'month', group: group)
      expect(plan.name).to eq(@plan_name)
    end
  end

  context "on update" do
    before :each do
      allow(Stripe::Plan).to receive(:create).and_return(double(id: SecureRandom.hex, name: SecureRandom.hex))
    end

    let(:plan){ Plan.create(amount: 500, interval: 'month', group: group) }

    describe "update_stripe_plan" do
      it "should return false if plan already has subscriptions" do
        allow(plan).to receive(:subscriptions).and_return([1,2])
        expect(plan.send(:update_stripe_plan)).to eq(false)
      end
    end
  end
end
