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
    self.asset_globs << [root, extension, options || {}]
  end

  def self.register_asset(asset, opts=nil)
    if asset =~ /\.js$|\.js\.erb$|\.js\.es6$|\.coffee$|\.coffee\.erb/
      # if opts == :admin
      #   self.admin_javascripts << asset
      # else
      #   if opts == :server_side
      #     self.server_side_javascripts << asset
      #   end
      self.javascripts << asset
      # end
    elsif asset =~ /\.css$|\.scss$/
      # if opts == :mobile
      #   self.mobile_stylesheets << asset
      # elsif opts == :desktop
      #   self.desktop_stylesheets << asset
      # elsif opts == :variables
      #   self.sass_variables << asset
      # else
        self.stylesheets << asset
      # end

    # elsif asset =~ /\.hbs$/
    #   self.handlebars << asset
    # elsif asset =~ /\.js\.handlebars$/
    #   self.handlebars << asset
    end
  end

  def self.insert_code(key)
    self.code_insertions[key]&.join('\n')
  end
end
