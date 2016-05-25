require 'fileutils'
require 'plugin_registry'

module Plugin
  class Instance
    attr_accessor :path#, :directory

    [:assets, :initializers, :javascripts, :styles].each do |att|
      class_eval %Q{
        def #{att}
          @#{att} ||= []
        end
      }
    end

    def self.find_all(parent_path)
      [].tap { |plugins|
        # also follows symlinks - http://stackoverflow.com/q/357754
        Dir["#{parent_path}/**/*/**/plugin.rb"].sort.each do |path|

          source = File.read(path)
  #        metadata = Plugin::Metadata.parse(source)
          plugins << self.new(nil, path)
        end
      }
    end

    def initialize(metadata=nil, path=nil)
      @metadata = metadata
      @path = path
      #@directory = path.match(/(.*)\/plugin.rb/)[1]
      @idx = 0
    end

    def activate!
      if @path
        root_path = "#{File.dirname(@path)}/assets/javascripts"
        PluginRegistry.register_glob(root_path, 'coffee.erb')
      end

      self.instance_eval File.read(path), path # execute all code of the plugin main file ! (named plugin.rb)

      register_assets! unless assets.blank?

      Rails.configuration.assets.paths << File.dirname(path) + "/assets"

      Rails.configuration.assets.precompile += [lambda do |filename, path|
        (Dir["plugins/*/assets/templates"].any? { |p| path.include?(p) }) # useless because already included in application.css/js || (%w(.js).include?(File.extname(filename)) && Dir["plugins/*/assets/javascripts"].any? { |p| path.include?(p) }) || (%w(.css).include?(File.extname(filename)) && Dir["plugins/*/assets/stylesheets"].any? { |p| path.include?(p) })
      end] #

      Rails.configuration.sass.load_paths += Dir["plugins/*/assets/stylesheets"]


      # Automatically include rake tasks
      Rake.add_rakelib(File.dirname(path) + "/lib/tasks")

      # Automatically include migrations
      Rails.configuration.paths["db/migrate"] << File.dirname(path) + "/db/migrate"
    end

    def register_asset(file, opts=nil) # to be used by the plugin !
      full_path = File.dirname(path) << "/assets/" << file
      assets << [full_path, opts]
    end

    def register_code_insertion(key, code)
      PluginRegistry.code_insertions[key] ||= []
      PluginRegistry.code_insertions[key] << code
    end

    def register_css(style) # useless ?
      styles << style
    end

    def after_initialize(&block)
      initializers << block
    end

    def notify_after_initialize
      initializers.each do |callback|
        begin
          callback.call(self)
        rescue ActiveRecord::StatementInvalid => e
          # When running db:migrate for the first time on a new database, plugin initializers might
          # try to use models. Tolerate it.
          raise e unless e.message.try(:include?, "PG::UndefinedTable")
        end
      end
    end

    protected
      def register_assets!
        assets.each do |asset, opts|
          PluginRegistry.register_asset(asset, opts)
        end
      end
  end
end
