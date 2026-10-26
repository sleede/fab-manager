# frozen_string_literal: true

require 'test_helper'
require 'sso_logger'

class SsoLoggerTest < ActiveSupport::TestCase
  def setup
    @original_sso_debug = ENV['SSO_DEBUG']
  end

  def teardown
    if @original_sso_debug.nil?
      ENV.delete('SSO_DEBUG')
    else
      ENV['SSO_DEBUG'] = @original_sso_debug
    end
  end

  # FM-12: Test boolean parsing matrix for SSO_DEBUG
  test 'debug is disabled when SSO_DEBUG is absent, empty, false, 0, or arbitrary non-true string' do
    [nil, '', '   ', 'false', 'FALSE', '0', 'no', 'disabled', 'null'].each do |val|
      if val.nil?
        ENV.delete('SSO_DEBUG')
      else
        ENV['SSO_DEBUG'] = val
      end

      out, = capture_io do
        logger = SsoLogger.new
        logger.debug('sensitive_sso_token_12345')
      end

      assert_empty out, "Expected no debug output when SSO_DEBUG=#{val.inspect}, but got: #{out}"
    end
  end

  test 'debug is enabled only when SSO_DEBUG is true (case-insensitive with strip)' do
    ['true', 'TRUE', ' TrUe ', 'True'].each do |val|
      ENV['SSO_DEBUG'] = val

      out, = capture_io do
        logger = SsoLogger.new
        logger.debug('test_debug_marker_67890')
      end

      assert_includes out, 'test_debug_marker_67890', "Expected debug output when SSO_DEBUG=#{val.inspect}"
      assert_includes out, '[SSO]'
    end
  end

  test 'info, warn, and error methods log regardless of SSO_DEBUG setting' do
    ENV['SSO_DEBUG'] = 'false'

    out_info, = capture_io do
      logger = SsoLogger.new
      logger.info('info_marker')
    end
    assert_includes out_info, 'info_marker'

    out_warn, = capture_io do
      logger = SsoLogger.new
      logger.warn('warn_marker')
    end
    assert_includes out_warn, 'warn_marker'

    out_error, = capture_io do
      logger = SsoLogger.new
      logger.error('error_marker')
    end
    assert_includes out_error, 'error_marker'
  end

  # FM-12: Ensure sensitive credentials and raw mapping values are not dumped
  test 'SingleSignOnConcern#from_omniauth does not leak auth credentials or raw mapping values in logs' do
    ENV['SSO_DEBUG'] = 'true'

    original_provider = Rails.configuration.auth_provider
    fake_provider = Struct.new(:strategy_name).new('github')
    begin
      Rails.configuration.auth_provider = fake_provider

      auth_hash = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: 'user_oauth_123',
        credentials: { token: 'gho_secret_access_token_99999' },
        info: {
          name: 'Secret User Name',
          email: 'secret_user@example.com',
          mapping: { 'user.email' => 'secret_user@example.com', 'profile.first_name' => 'SecretFirst' }
        }
      )

      out, = capture_io do
        User.from_omniauth(auth_hash)
      end

      # Sensitive tokens and values must NOT be present in log output
      refute_includes out, 'gho_secret_access_token_99999'
      refute_includes out, 'with value='
      refute_includes out, 'secret_user@example.com'
      refute_includes out, 'SecretFirst'

      # Safe metadata can be present
      assert_includes out, 'provider=github'
      assert_includes out, 'mapping info user.email'
    ensure
      Rails.configuration.auth_provider = original_provider
    end
  end

  test 'SsoOauth2Provider#raw_info does not log raw endpoint query secrets or access tokens' do
    ENV['SSO_DEBUG'] = 'true'

    fake_mapping = Struct.new(:api_endpoint).new('/userinfo?api_key=FM12_SECRET_API_KEY_MARKER')
    fake_provider = Struct.new(:auth_provider_mappings).new([fake_mapping])
    fake_response = Struct.new(:parsed).new({ 'email' => 'user_private@example.com' })
    fake_token = Object.new
    fake_token.define_singleton_method(:get) { |_endpoint| fake_response }

    strategy = OmniAuth::Strategies::SsoOauth2Provider.new(nil)
    strategy.instance_variable_set(:@access_token, fake_token)

    singleton_class = OmniAuth::Strategies::SsoOauth2Provider.singleton_class
    original_method = OmniAuth::Strategies::SsoOauth2Provider.method(:active_provider) rescue nil
    singleton_class.define_method(:active_provider) { fake_provider }
    begin
      out, = capture_io do
        info = strategy.raw_info
        assert_equal({ '/userinfo?api_key=FM12_SECRET_API_KEY_MARKER': { 'email' => 'user_private@example.com' } }, info)
      end

      refute_includes out, 'FM12_SECRET_API_KEY_MARKER'
      refute_includes out, 'user_private@example.com'
      refute_includes out, 'access_token'
      assert_includes out, '[raw_info] fetching data'
    ensure
      if original_method
        singleton_class.define_method(:active_provider, original_method)
      else
        singleton_class.remove_method(:active_provider)
      end
    end
  end
end
