require 'rails_helper'

RSpec.describe Project, type: :model do

  describe 'create' do
    it 'is success with author, name and description'
    it 'is invalid without author'
    it 'is invalid without name'
    it 'is invalid without description'
    it 'should auto generate slug by name'
  end

  it 'save as draft by default'

  it 'should can published'

  it 'should have a published time after published'

  it 'can only add one project main image'

  it 'can have many project caos'

  it 'can have many machines'

  it 'can have many components'

  it 'can have many project steps'

  it 'can add a licence'
end
