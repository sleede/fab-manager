require 'rails_helper'

RSpec.describe Availability, type: :model do

  describe 'create' do
    it 'is success with start at, end at and type'
    it 'is invalid without start at'
    it 'is invalid without end at'
    it 'is invalid without type'
    it 'is invalid type isnt in [training, machines, event]'
    it 'is invalid without training_ids when type training'
    it 'is invalid without machine_ids when type machines'
  end

  it 'should can associate one or many reservations'

  it 'should can destroy if dont any reservations'

  it 'should get a title'

  it 'should set a number of places'

  it 'should be completed when number of reservations equal number of places'
end
