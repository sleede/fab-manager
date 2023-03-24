# frozen_string_literal: true

load 'plugin/instance.rb'

# the FabManager application
module FabManager
  class << self
    attr_reader :plugins
  end

  def self.activate_plugins!
    all_plugins = Plugin::Instance.find_all(Rails.root.join('plugins'))

    @plugins = []
    all_plugins.each do |p|
      p.activate!
      @plugins << p
    end
  end
end
