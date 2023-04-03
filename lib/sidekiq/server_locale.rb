# frozen_string_literal: true

# module definition
module FabManager::Middleware; end

# Provides localization in workers
class FabManager::Middleware::ServerLocale
  def call(_worker_class, job, _queue)
    locale = job['locale'] || Rails.application.secrets.rails_locale
    I18n.with_locale(locale) do
      yield
    end
  end
end
