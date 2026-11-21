# frozen_string_literal: true

# Resolve translation subtrees (eg. 'app.public') for the front-end, honoring the I18n fallbacks chain.
#
# I18n fallbacks work key by key: when the requested locale contains only a part of a subtree, `I18n.t('app.public')`
# returns that partial subtree and ignores the fallback locales. This service deep-merges the subtrees found along the
# fallback chain (eg. de-x-informal -> de), so that a locale variant only needs to contain the strings that differ
# from its parent locale.
class TranslationsService
  class << self
    # @param key [String] the translation key, eg. 'app.public'
    # @param locale [String, Symbol] the requested locale
    # @return [Hash, String, nil] the merged subtree, the translated string if the key is a leaf, or nil if the key
    #   does not exist in any locale of the fallback chain
    def lookup(key, locale = I18n.locale)
      values = fallback_chain(locale).filter_map do |loc|
        I18n.t(key, locale: loc, fallback: false) if I18n.exists?(key, locale: loc, fallback: false)
      end
      return values.first unless values.any? && values.all?(Hash)

      # merge from the least specific locale to the most specific one, so that the latter takes precedence
      # (nil values, eg. empty keys exported by the translation platform, do not override the fallback)
      values.reverse.reduce do |merged, value|
        merged.deep_merge(value) { |_key, fallback, specific| specific.nil? ? fallback : specific }
      end
    end

    # @param locale [String, Symbol]
    # @return [Array<Symbol>] the available locales of the I18n fallback chain, starting with the given locale
    def fallback_chain(locale)
      chain = I18n.respond_to?(:fallbacks) ? I18n.fallbacks[locale] : [locale.to_sym]
      chain.select { |loc| I18n.locale_available?(loc) }
    end
  end
end
