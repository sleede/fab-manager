# frozen_string_literal: true

# Deals with the yml file keeping the configuration of the current authentication provider
class ProviderConfig
  def initialize
    @config = if File.exist?('config/auth_provider.yml')
                content = YAML.safe_load_file('config/auth_provider.yml')
                content.blank? ? simple_provider : content.with_indifferent_access
              else
                simple_provider
              end
  end

  def db
    AuthProvider.find(@config[:id])
  end

  def oidc_config
    return nil unless @config[:providable_type] == 'OpenIdConnectProvider'

    (@config[:providable_attributes].keys.filter { |n| !n.start_with?('client__') && n != 'profile_url' }.map do |n|
      val = @config[:providable_attributes][n]
      val.join(' ') if n == 'scope'
      [n, val]
    end).push(
      ['client_options', @config[:providable_attributes].keys.filter { |n| n.start_with?('client__') }.to_h do |n|
        [n.sub('client__', ''), @config[:providable_attributes][n]]
      end]
    ).to_h
  end

  def method_missing(method, *args)
    return map_value(@config[method]) if @config.key?(method)

    return map_value(@config["#{method}_attributes"]) if @config.key?("#{method}_attributes")

    super
  end

  def respond_to_missing?(name)
    @config.key?(name) || @config.key("#{name}_attributes")
  end

  def self.write_active_provider
    data = ApplicationController.render(
      template: 'auth_provider/provider',
      locals: { provider: AuthProvider.active },
      handlers: [:jbuilder],
      formats: [:json]
    )
    file_path = Rails.root.join('config/auth_provider.yml')
    File.open(file_path, File::WRONLY | File::CREAT) do |file|
      file.truncate(0)
      file.write(JSON.parse(data).to_yaml)
    end
  end

  private

  def map_value(item)
    return Struct.new(*item.symbolize_keys.keys).new(*item.values) if item.is_a?(Hash)

    return item.map { |v| map_value(v) } if item.is_a?(Array)

    item
  end

  # @return [Hash{Symbol->String}]
  def simple_provider
    {
      providable_type: 'DatabaseProvider',
      name: 'DatabaseProvider::SimpleAuthProvider',
      strategy_name: 'database-simpleauthprovider'
    }
  end
end
