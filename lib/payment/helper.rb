# frozen_string_literal: true

# Payments module
module Payment; end

# Generic gateway helpers
class Payment::Helper
  def self.enabled?; end
  def self.human_error(_error); end
end
