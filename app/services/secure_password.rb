# frozen_string_literal: true

# Ensure the passwords are secure enough
class SecurePassword
  LOWER_LETTERS = ('a'..'z').to_a
  UPPER_LETTERS = ('A'..'Z').to_a
  DIGITS = ('0'..'9').to_a
  SPECIAL_CHARS = ['!', '#', '$', '%', '&', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', ']', '^', '_', '{',
                   '|', '}', '~', "'", '`', '"'].freeze

  def self.generate
    (LOWER_LETTERS.sample(4) + UPPER_LETTERS.sample(4) + DIGITS.sample(4) + SPECIAL_CHARS.sample(4)).shuffle.join
  end

  def self.secured?(password)
    password_as_array = password.chars
    password_as_array.any? { |c| c.in? LOWER_LETTERS } &&
      password_as_array.any? { |c| c.in? UPPER_LETTERS } &&
      password_as_array.any? { |c| c.in? DIGITS } &&
      password_as_array.any? { |c| c.in? SPECIAL_CHARS }
  end
end
