require 'rails_helper'

RSpec.describe Machine, type: :model do

  describe 'create' do
    it 'is success with name, image, description and spec'
    it 'is invalid without name'
    it 'is invalid without image'
    it 'is invalid without description'
    it 'is invalid without spec'
    it 'should auto generate slug by name'
  end

  it 'can have many machine files'

  it 'can have many projects'

  it 'can have many trainings'

  it 'should return an amount by user group'
end
