# frozen_string_literal: true

require 'test_helper'

# Check that partial locale variants (eg. de-x-informal) fall back to their parent locale, key by key
class TranslationsServiceTest < ActiveSupport::TestCase
  setup do
    I18n.backend.store_translations(:de, test_fallback: { formal: 'Sie', shared: 'Gemeinsam', nested: { one: 'Eins', two: 'Zwei' } })
    I18n.backend.store_translations(:'de-x-informal', test_fallback: { formal: 'du', nested: { two: 'zwo', empty: nil } })
  end

  teardown do
    I18n.reload!
  end

  test 'the informal German falls back to the formal German' do
    assert I18n.available_locales.include?(:'de-x-informal')
    assert_equal %i[de-x-informal de], TranslationsService.fallback_chain('de-x-informal').first(2)
  end

  test 'single keys fall back to the parent locale' do
    assert_equal 'du', I18n.t('test_fallback.formal', locale: 'de-x-informal')
    assert_equal 'Gemeinsam', I18n.t('test_fallback.shared', locale: 'de-x-informal')
    assert_equal 'Eins', I18n.t('test_fallback.nested.one', locale: 'de-x-informal')
  end

  test 'subtrees are deep-merged along the fallback chain' do
    expected = { formal: 'du', shared: 'Gemeinsam', nested: { one: 'Eins', two: 'zwo', empty: nil } }
    assert_equal expected, TranslationsService.lookup('test_fallback', 'de-x-informal')
  end

  test 'nil values do not override the fallback values' do
    I18n.backend.store_translations(:'de-x-informal', test_fallback: { shared: nil })
    assert_equal 'Gemeinsam', TranslationsService.lookup('test_fallback', 'de-x-informal')[:shared]
  end

  test 'a leaf key returns the most specific string' do
    assert_equal 'du', TranslationsService.lookup('test_fallback.formal', 'de-x-informal')
    assert_equal 'Gemeinsam', TranslationsService.lookup('test_fallback.shared', 'de-x-informal')
  end

  test 'a locale without variant returns its own subtree' do
    expected = { formal: 'Sie', shared: 'Gemeinsam', nested: { one: 'Eins', two: 'Zwei' } }
    assert_equal expected, TranslationsService.lookup('test_fallback', 'de')
  end

  test 'a missing key returns nil' do
    assert_nil TranslationsService.lookup('test_fallback.does_not_exist', 'de-x-informal')
  end

  test 'the informal German locale files are partial and fall back to the formal German' do
    informal = TranslationsService.lookup('app.public', 'de-x-informal')
    formal = I18n.t('app.public', locale: :de)
    assert_equal 'Dein Vorname', informal.dig(:projects_show, :your_first_name)
    assert_equal formal.dig(:projects_show, :your_first_name_is_required), informal.dig(:projects_show, :your_first_name_is_required)
    assert_equal 'Du bist bereits angemeldet.', I18n.t('devise.failure.already_authenticated', locale: 'de-x-informal')
    assert_equal I18n.t('devise.failure.locked', locale: :de), I18n.t('devise.failure.locked', locale: 'de-x-informal')
  end
end
