# frozen_string_literal: true

Rails.application.routes.default_url_options.merge!(
  host: Rails.application.secrets.default_host,
  protocol: Rails.application.secrets.default_protocol
)