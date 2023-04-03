# frozen_string_literal: true

# SSO and authentication relative tasks
namespace :fablab do
  namespace :auth do
    desc 'switch the active authentication provider'
    task :switch_provider, [:provider] => :environment do |_task, args|
      providers = AuthProvider.all.inject('') { |str, item| "#{str}#{item[:name]}, " }
      unless args.provider
        puts "\e[0;31mERROR\e[0m: You must pass a provider name to activate. Available providers are: #{providers[0..-3]}"
        next
      end

      if AuthProvider.find_by(name: args.provider).nil?
        puts "\e[0;31mERROR\e[0m: the provider '#{args.provider}' does not exists. Available providers are: #{providers[0..-3]}"
        next
      end

      if AuthProvider.active.name == args.provider
        puts "\e[0;31mERROR\e[0m: the provider '#{args.provider}' is already enabled"
        next
      end

      # disable previous provider
      prev_prev = AuthProvider.previous
      prev_prev&.update(status: 'pending')

      AuthProvider.active.update(status: 'previous') unless AuthProvider.active.name == 'DatabaseProvider::SimpleAuthProvider'

      # enable given provider
      AuthProvider.find_by(name: args.provider).update(status: 'active')

      # migrate the current users.
      if AuthProvider.active.providable_type == DatabaseProvider.name
        User.all.each do |user|
          # Concerns local database provider
          user.update(auth_token: nil)
        end
      else
        # Concerns any providers except local database
        User.all.each(&:generate_auth_migration_token)
      end

      # write the configuration to file
      require 'provider_config'
      ProviderConfig.write_active_provider

      # ask the user to restart the application
      next if Rails.env.test?

      puts "\n\e[0;32m#{args.provider} successfully enabled\e[0m"

      puts "\n\e[0;33m⚠ WARNING\e[0m: Please consider the following, otherwise the authentication will be bogus:"
      puts "\t1) RESTART the application"
      puts "\t2) NOTIFY the current users with `rails fablab:auth:notify_changed`\n\n"
    end

    desc 'notify users that the auth provider has changed'
    task notify_changed: :environment do
      I18n.locale = I18n.default_locale

      # notify every users if the provider is not local database provider
      if AuthProvider.active.providable_type != DatabaseProvider.name
        User.all.each do |user|
          NotificationCenter.call type: 'notify_user_auth_migration',
                                  receiver: user,
                                  attached_object: user
        end
      end

      puts "\nUsers successfully notified\n\n"
    end

    desc 'display the current active authentication provider'
    task current: :environment do
      puts "Current active authentication provider: #{AuthProvider.active.name}"
    end

    desc 'write the provider config to a configuration file'
    task write_provider: :environment do
      require 'provider_config'
      ProviderConfig.write_active_provider
    end
  end
end
