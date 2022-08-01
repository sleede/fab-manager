class SecurePassword
  LOWER_LETTERS = ('a'..'z').to_a
  UPPER_LETTERS = ('A'..'Z').to_a
  DIGITS = ('0'..'9').to_a
  SPECIAL_CHARS = ["!", "#", "$", "%", "&", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "@", "[", "]", "^", "_", "{", "|", "}", "~", "'", "`", '"']

  def self.generate
    (LOWER_LETTERS.shuffle.first(4) + UPPER_LETTERS.shuffle.first(4) + DIGITS.shuffle.first(4) + SPECIAL_CHARS.shuffle.first(4)).shuffle.join
  end

  def self.is_secured?(password)
    password_as_array = password.split("")
    password_as_array.any? {|c| c.in? LOWER_LETTERS } &&
      password_as_array.any? {|c| c.in? UPPER_LETTERS } &&
      password_as_array.any? {|c| c.in? DIGITS }  &&
      password_as_array.any? {|c| c.in? SPECIAL_CHARS }
  end
end