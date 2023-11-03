# frozen_string_literal: true

module LabelI18nConcern
  extend ActiveSupport::Concern

  def label
    super.present? ? super : I18n.t(label_i18n_path)
  end
end
