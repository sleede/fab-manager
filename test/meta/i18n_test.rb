# frozen_string_literal: true

require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  # Do not use I18n.default_locale, reference locale can be different
  REFERENCE_LOCALE = :fr
  LOCALES_TO_CHECK = [:en]

  SKIP_FILES = %w[
    devise
    rails
  ].freeze

  FILE_IDS = Rails.root.glob("config/locales/*.#{REFERENCE_LOCALE}.yml")
    .map { File.basename(_1) }
    .map { _1.split(".")[0..-3].join(".") } # view.admin.fr.yml -> view.admin
    .reject { SKIP_FILES.include?(_1) }

  LOCALES_TO_CHECK.each do |locale|
    FILE_IDS.each do |file_id|
      test "#{file_id}.#{locale}.yml have same keys as #{file_id}.#{REFERENCE_LOCALE}.yml" do
        reference_keys = read_keys(REFERENCE_LOCALE, file_id)
        locale_keys = read_keys(locale, file_id)

        reference_keys.each_with_index do |reference_key, index|
          next if index.zero?

          unless reference_key[0] == "#"
            assert_equal reference_key, locale_keys[index], "invalid key at line #{index + 1}"
          end
        end
      end
    end
  end

  def read_keys(locale, file_id)
    file = Rails.root.join("config/locales/#{file_id}.#{locale}.yml")

    File.read(file)
      .split("\n")
      .map { _1.split(":", 2).first.to_s.strip }
  end
end
