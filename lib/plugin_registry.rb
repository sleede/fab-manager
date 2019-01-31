class PluginRegistry
  class << self
    attr_writer :javascripts
    attr_writer :stylesheets

    def asset_globs
      @asset_globs ||= Set.new
    end

    def javascripts
      @javascripts ||= Set.new
    end

    def stylesheets
      @stylesheets ||= Set.new
    end

    def code_insertions
      @code_insertions ||= {}
    end
  end

  def self.register_glob(root, extension, options=nil)
    asset_globs << [root, extension, options || {}]
  end

  def self.register_asset(asset, _opts = nil)
    if asset =~ /\.js$|\.js\.erb$|\.js\.es6$|\.coffee$|\.coffee\.erb/
      javascripts << asset
    elsif asset =~ /\.css$|\.scss$/
      stylesheets << asset
    end
  end

  def self.insert_code(key)
    code_insertions[key]&.join('\n')
  end
end
