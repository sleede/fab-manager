# frozen_string_literal: true

# retrieve the current Fab-manager version
class Version
  def self.current
    package = File.read('package.json')
    JSON.parse(package)['version']
  end
end
