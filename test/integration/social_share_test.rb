# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

# Link previews of shared events, trainings and projects (OpenGraph / Twitter Card meta tags)
class SocialShareTest < ActionDispatch::IntegrationTest
  WHATSAPP_UA = 'WhatsApp/2.23.20.0 A'

  def meta_content(attribute, name)
    node = Nokogiri::HTML(response.body).at_css("meta[#{attribute}='#{name}']")
    node&.[]('content')
  end

  # absolute URLs are built from DEFAULT_HOST / DEFAULT_PROTOCOL when set, else from the request
  def base_url
    host = Rails.application.secrets.default_host.presence || 'www.example.com'
    "#{Rails.application.secrets.default_protocol.presence || 'http'}://#{host}"
  end

  def og(name)
    meta_content('property', "og:#{name}")
  end

  test 'share an event with its image' do
    event = Event.find(2)
    event.event_image&.destroy
    event.reload.create_event_image!(attachment: fixture_file_upload('event/Party.jpg'))

    get "/events/#{event.id}", headers: { 'HTTP_USER_AGENT' => WHATSAPP_UA }

    assert_response :success
    assert_match Mime[:html].to_s, response.content_type
    assert_equal event.title, og('title')
    assert_equal "#{base_url}/events/#{event.id}", og('url')
    assert_equal 'website', og('type')
    assert_equal Setting.get('fablab_name'), og('site_name')
    assert og('description').start_with?('Apprenez à fabriquer vous-même votre skateboard : - impression 3D')
    assert_not_includes og('description'), "\n"
    assert_match %r{\A#{Regexp.escape(base_url)}/uploads/event_image/[0-9]+/large_event_image\.jpg\z}, og('image')
    assert_not_nil og('image:width')
    assert_equal og('image'), meta_content('name', 'twitter:image')
    assert_equal 'summary_large_image', meta_content('name', 'twitter:card')
    assert_equal "#{base_url}/events/#{event.id}", Nokogiri::HTML(response.body).at_css('link[rel=canonical]')['href']
    # humans are redirected to the single page application
    assert_includes response.body, "window.location.replace(\"#{base_url}/#!/events/#{event.id}\")"
    assert_includes response.body, "href=\"#{base_url}/#!/events/#{event.id}\""
  end

  test 'share a training' do
    training = Training.find(1)
    training.update!(description: '<p>Learn <b>3D printing</b> &amp; more</p>')

    get "/trainings/#{training.slug}"

    assert_response :success
    assert_equal training.name, og('title')
    assert_equal 'Learn 3D printing & more', og('description')
    assert_equal "#{base_url}/trainings/#{training.slug}", og('url')
    assert_includes response.body, "#{base_url}/#!/trainings/#{training.slug}"
  end

  test 'share a published project' do
    project = Project.published.first
    project.update!(description: "<p>#{'lorem ipsum ' * 100}</p>")

    get "/projects/#{project.slug}"

    assert_response :success
    assert_equal project.name, og('title')
    assert_equal "#{base_url}/projects/#{project.slug}", og('url')
    assert og('description').length <= SocialBotController::DESCRIPTION_LENGTH
    assert og('description').end_with?('…')
    assert_includes response.body, "#{base_url}/#!/projects/#{project.slug}"
  end

  test 'meta tags are escaped' do
    event = Event.find(3)
    event.update!(title: '"><script>alert(1)</script>')

    get "/events/#{event.id}"

    assert_response :success
    assert_not_includes response.body, '<script>alert(1)</script>'
    assert_equal '"><script>alert(1)</script>', og('title')
  end

  test 'unknown, deleted, disabled or unpublished items are not found' do
    get '/events/999999'
    assert_response :not_found

    event = Event.find(3)
    event.update!(deleted_at: Time.current)
    get "/events/#{event.id}"
    assert_response :not_found

    get '/trainings/unknown-training'
    assert_response :not_found

    training = Training.find(2)
    training.update!(disabled: true)
    get "/trainings/#{training.slug}"
    assert_response :not_found

    draft = Project.create!(
      name: 'Shared Draft Test',
      description: '<p>Secret draft</p>',
      author: StatisticProfile.find(5),
      licence_id: 1,
      status_id: 1,
      state: 'draft'
    )
    get "/projects/#{draft.slug}"
    assert_response :not_found
    get "/projects/#{draft.id}"
    assert_response :not_found
  end

  test 'legacy escaped fragment route still works for listed bots' do
    get "/?_escaped_fragment_=/events/#{Event.find(2).id}", headers: { 'HTTP_USER_AGENT' => 'facebookexternalhit/1.1' }

    assert_response :success
    assert_equal "#{base_url}/events/2", og('url')
  end

  test 'listed bots fetching the root get the application' do
    # the application layout embeds compiled assets, which are not the behavior under test
    manifest = Webpacker.instance.manifest
    manifest.stub(:lookup!, ->(name, *) { "/packs-test/#{name}" }) do
      manifest.stub(:lookup_pack_with_chunks!, ->(name, **) { ["/packs-test/#{name}"] }) do
        get '/', headers: { 'HTTP_USER_AGENT' => 'facebookexternalhit/1.1' }
      end
    end

    assert_response :success
    assert_equal 'application', controller.controller_name
    assert_nil og('url')
  end
end
