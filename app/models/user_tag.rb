# frozen_string_literal: true

# UserTag is the relation table between a Tag and an User.
# Users with Tags, can book Availabilities associated with the same Tags.
class UserTag < ApplicationRecord
  belongs_to :user
  belongs_to :tag
end
