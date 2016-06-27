## Helper method: will return true if the current string
## can be parsed as a number (float or integer), false otherwise
# exemples:
# "2" => true
# "4.5" => true
# "hello" => false
# "" => false
class String
  def is_number?
    true if Float(self) rescue false
  end
end