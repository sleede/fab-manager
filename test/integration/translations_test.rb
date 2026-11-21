# frozen_string_literal: true

require 'test_helper'

# Front-end translations API
class TranslationsTest < ActionDispatch::IntegrationTest
  test 'get the front-end translations of a locale' do
    get '/api/translations/de/app.public'

    assert_response :success
    res = json_response(response.body)
    assert_equal I18n.t('app.public.projects_show.your_first_name', locale: :de), res.dig(:app, :public, :projects_show, :your_first_name)
  end

  test 'get the front-end translations of a partial locale variant merged with its parent locale' do
    get '/api/translations/de-x-informal/app.public'

    assert_response :success
    res = json_response(response.body)
    projects_show = res.dig(:app, :public, :projects_show)
    # overridden by the informal variant
    assert_equal 'Dein Vorname', projects_show[:your_first_name]
    # not overridden: inherited from the formal German
    assert_equal I18n.t('app.public.projects_show.your_first_name_is_required', locale: :de), projects_show[:your_first_name_is_required]
    # subtrees missing from the variant are inherited too
    assert_equal I18n.t('app.public.about', locale: :de), res.dig(:app, :public, :about)
  end

  test 'get a single front-end translation of a partial locale variant' do
    get '/api/translations/de-x-informal/app.public.projects_show.your_surname'

    assert_response :success
    assert_equal 'Dein Nachname', json_response(response.body).dig(:app, :public, :projects_show, :your_surname)
  end
end
