module FabManager
  module Middleware
    class ServerLocale
      def call(worker_class, job, queue)
        locale = job['locale'] || Rails.application.secrets.rails_locale
        I18n.with_locale(locale) do
          yield
        end
      end
    end
  end
end