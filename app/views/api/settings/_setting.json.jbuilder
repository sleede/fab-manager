# frozen_string_literal: true

json.extract! setting, :name, :value, :last_update
json.localized I18n.t("settings.#{setting[:name]}")
