# frozen_string_literal: true

# This helper loads the actual strategy without booting Rails or connecting to a database.
# Only the provider configuration is substituted; XML parsing and signature verification are real.
require 'bundler/setup'
require 'logger'
require 'minitest/autorun'
require 'minitest/mock'
require 'rails'
require 'active_support/all'
require 'jsonpath'
require 'rack/mock'
require 'cgi'

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

# Local test identities and fresh signing keys never refer to a real identity provider.
module SamlSecurityHelper
  SP_ENTITY = 'https://sp.example.test/metadata'
  IDP_ENTITY = 'https://idp.example.test/metadata'
  CALLBACK = 'https://sp.example.test/auth/security_saml/callback'
  REQUEST_ID = '_local_authn_request'
  NAME_ID = 'member@example.test'
  Mapping = Struct.new(:local_model, :local_field, :api_field, :api_endpoint, :transformation)
  Provider = Struct.new(:providable_type, :strategy_name, :auth_provider_mappings)
  PROVIDER = Provider.new('SamlProvider', 'security_saml', [
                            Mapping.new('user', 'email', '$.email', 'user_info', nil),
                            Mapping.new('profile', 'first_name', '$.first_name', 'user_info', nil),
                            Mapping.new('profile', 'last_name', '$.last_name', 'user_info', nil)
                          ]).freeze

  def signing_key
    @signing_key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def signing_certificate
    @signing_certificate ||= OpenSSL::X509::Certificate.new.tap do |certificate|
      certificate.version = 2
      certificate.serial = 1
      certificate.subject = OpenSSL::X509::Name.parse('/CN=local-saml-fixture.example.test')
      certificate.issuer = certificate.subject
      certificate.public_key = signing_key.public_key
      certificate.not_before = Time.now.utc - 60
      certificate.not_after = Time.now.utc + 3600
      certificate.sign(signing_key, OpenSSL::Digest.new('SHA256'))
    end
  end

  def sign_xml(xml)
    document = XMLSecurity::Document.new(xml)
    document.sign_document(signing_key, signing_certificate, XMLSecurity::Document::RSA_SHA256, XMLSecurity::Document::SHA256)
    document.to_s
  end

  def response_xml(signed: true, **overrides)
    now = Time.now.utc
    values = {
      issuer: IDP_ENTITY, audience: SP_ENTITY, destination: CALLBACK, recipient: CALLBACK,
      request_id: REQUEST_ID, name_id: NAME_ID, issue_instant: now.iso8601,
      not_before: (now - 60).iso8601, not_after: (now + 300).iso8601
    }.merge(overrides)
    template = File.read(File.expand_path('../fixtures/files/saml/response.xml', __dir__))
    document = REXML::Document.new(sprintf(template, values))
    assertion = document.root.elements['saml:Assertion']
    document.root.delete_element(assertion)
    document.root.add_element(REXML::Document.new(signed ? sign_xml(assertion.to_s) : assertion.to_s).root)
    document.to_s
  end

  def strategy_options
    {
      name: 'security_saml', sp_entity_id: SP_ENTITY, assertion_consumer_service_url: CALLBACK,
      idp_sso_service_url: 'https://idp.example.test/sso', idp_slo_service_url: 'https://idp.example.test/logout',
      idp_cert: signing_certificate.to_pem, slo_default_relay_state: '/',
      security: OneLogin::RubySaml::Settings::DEFAULTS[:security].merge(want_assertions_signed: true)
    }
  end

  def strategy_request(path, params, session: {}, options: {}, method: 'POST')
    env = Rack::MockRequest.env_for("https://sp.example.test/auth/security_saml/#{path}", method: method, params: params)
    env['rack.session'] = session
    application = lambda do |request_env|
      @authentication = request_env['omniauth.auth']
      [200, { 'Content-Type' => 'text/plain' }, ['Authenticated']]
    end
    strategy = OmniAuth::Strategies::SsoSamlProvider.new(application, strategy_options.merge(options))
    OmniAuth::Strategies::SsoSamlProvider.stub(:active_provider, PROVIDER) do
      strategy.call(env)
    end
  end

  def authenticate(xml, options: {}, session: {})
    strategy_request('callback', { 'SAMLResponse' => Base64.strict_encode64(xml) }, session: session, options: options)
  end

  def logout_request(relay_state: '/', name_id: NAME_ID)
    xml = <<~XML
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_local_logout" Version="2.0"
        IssueInstant="#{Time.now.utc.iso8601}">
        <saml:Issuer>#{IDP_ENTITY}</saml:Issuer>
        <saml:NameID>#{name_id}</saml:NameID>
        <samlp:SessionIndex>_local_session</samlp:SessionIndex>
      </samlp:LogoutRequest>
    XML
    params = { 'SAMLRequest' => Base64.strict_encode64(xml), 'RelayState' => relay_state,
               'SigAlg' => XMLSecurity::Document::RSA_SHA256 }
    signed_query = params.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join('&')
    params.merge('Signature' => Base64.strict_encode64(signing_key.sign(OpenSSL::Digest.new('SHA256'), signed_query)))
  end

  def saml_session
    { 'saml_uid' => NAME_ID, 'saml_session_index' => '_local_session', 'application_user_id' => 'local-member' }
  end
end

configuration = Struct.new(:auth_provider).new(SamlSecurityHelper::PROVIDER)
Rails.stub(:configuration, configuration) do
  require 'omni_auth/strategies/sso_saml_provider'
end
