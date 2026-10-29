# frozen_string_literal: true

require_relative '../helpers/saml_security_helper'

# Exercises the application strategy and mapper with real locally signed SAML messages.
# Run without services: bundle exec ruby -Itest test/security/sso_saml_provider_test.rb
class SsoSamlProviderTest < Minitest::Test
  include SamlSecurityHelper

  def setup
    @previous_failure_handler = OmniAuth.config.on_failure
    OmniAuth.config.on_failure = lambda do |env|
      @failure = env['omniauth.error']
      [401, { 'Content-Type' => 'text/plain' }, ['SAML rejected']]
    end
  end

  def teardown
    OmniAuth.config.on_failure = @previous_failure_handler
  end

  def test_accepts_signed_assertion_and_maps_user_attributes
    session = {}
    result = authenticate(response_xml, session: session)

    assert_equal 200, result.first, @failure&.message
    assert_equal NAME_ID, @authentication.uid
    assert_equal 'member@example.test', @authentication.info.mapping['user.email']
    assert_equal 'Local', @authentication.info.mapping['profile.first_name']
    assert_equal 'Member', @authentication.info.mapping['profile.last_name']
    assert_equal NAME_ID, session['saml_uid']
    assert_equal '_local_session', session['saml_session_index']
  end

  def test_rejects_assertion_modified_after_signing
    assert_rejected(response_xml.gsub('member@example.test', 'attacker@example.test'), /signature|digest/i)
  end

  def test_rejects_assertion_with_an_untrusted_namespace_binding
    document = REXML::Document.new(response_xml)
    document.root.elements['saml:Assertion'].add_namespace('saml', 'urn:example:untrusted-assertion')

    assert_rejected(document.to_s, /assertion|schema|signature/i)
  end

  def test_rejects_unsigned_assertion_reusing_the_signed_assertion_id
    document = REXML::Document.new(response_xml)
    signed_assertion = document.root.elements['saml:Assertion']
    attacker_assertion = unsigned_attacker_assertion(id: signed_assertion.attributes['ID'])
    document.root.insert_before(signed_assertion, attacker_assertion)

    assert_rejected(document.to_s, /assertion|duplicat|schema/i)
  end

  def test_rejects_signed_assertion_wrapped_away_from_the_unsigned_identity
    document = REXML::Document.new(response_xml)
    signed_assertion = document.root.elements['saml:Assertion']
    document.root.delete_element(signed_assertion)
    extensions = REXML::Element.new('samlp:Extensions')
    wrapper = extensions.add_element('fixture:SignedAssertion', { 'xmlns:fixture' => 'urn:example:wrapping-fixture' })
    wrapper.add_element(signed_assertion)
    document.root.insert_before(document.root.elements['samlp:Status'], extensions)
    document.root.add_element(unsigned_attacker_assertion)

    assert_rejected(document.to_s, /assertion|schema|signature/i)
  end

  def test_rejects_unsigned_assertion
    assert_rejected(response_xml(signed: false), /signature|signed/i)
  end

  def test_rejects_signature_from_an_untrusted_certificate
    xml = response_xml
    @signing_key = nil
    @signing_certificate = nil

    assert_rejected(xml, /signature|fingerprint|certificate/i)
  end

  def test_rejects_signature_from_an_untrusted_key_presenting_the_trusted_certificate
    trusted_certificate = signing_certificate
    @signing_key = OpenSSL::PKey::RSA.new(2048)
    xml = response_xml

    assert_includes xml, Base64.strict_encode64(trusted_certificate.to_der)
    assert_rejected(xml, /key validation|signature/i)
  end

  def test_rejects_wrong_audience
    assert_rejected(response_xml(audience: 'https://other.example.test/metadata'), /audience/i)
  end

  def test_rejects_wrong_destination
    assert_rejected(response_xml(destination: 'https://other.example.test/callback'), /received at|destination/i)
  end

  def test_rejects_wrong_subject_recipient
    assert_rejected(response_xml(recipient: 'https://other.example.test/callback'), /subject\s*confirmation|recipient/i)
  end

  def test_rejects_expired_assertion
    assert_rejected(response_xml(not_after: (Time.now.utc - 60).iso8601), /expired|NotOnOrAfter|subject confirmation/i)
  end

  def test_rejects_assertion_not_yet_valid
    assert_rejected(response_xml(not_before: (Time.now.utc + 120).iso8601), /not yet valid|NotBefore/i)
  end

  # Exercise optional issuer and request-correlation validation with explicit settings.
  def test_validates_issuer_when_expected_idp_entity_is_configured
    options = { idp_entity_id: IDP_ENTITY }
    assert_equal 200, authenticate(response_xml, options: options).first
    assert_rejected(response_xml(issuer: 'https://other.example.test/metadata'), /issuer/i, options: options)
  end

  def test_correlates_response_when_expected_request_id_is_configured
    options = { matches_request_id: REQUEST_ID }
    assert_equal 200, authenticate(response_xml, options: options).first
    assert_rejected(response_xml(request_id: '_other_request'), /InResponseTo|AuthNRequest/i, options: options)
  end

  def test_rejects_doctype_before_authentication
    xml = response_xml.sub('<samlp:Response', '<!DOCTYPE samlp:Response [<!ENTITY local "fixture">]><samlp:Response')

    assert_rejected(xml, /doctype|dangerous|DTD/i)
  end

  def test_rejects_repeated_xml_declarations_before_authentication
    xml = "<?xml version=\"1.0\"?><?xml version=\"1.0\"?>#{response_xml}"

    assert_rejected(xml, /XML declaration is duplicated/i)
  end

  def test_signed_idp_logout_clears_session_and_preserves_local_relay_state
    session = saml_session
    result = strategy_request('slo', logout_request(relay_state: '/signed-out'), session: session, method: 'GET')

    assert_equal 302, result.first
    assert_empty session
    assert_equal '/signed-out', redirect_query(result)['RelayState']
  end

  def test_logout_rejects_tampered_redirect_signature_without_clearing_session
    session = saml_session
    params = logout_request
    params['RelayState'] = '/tampered'
    error = assert_raises(OmniAuth::Strategies::SAML::ValidationError) do
      strategy_request('slo', params, session: session, method: 'GET')
    end

    assert_match(/LogoutRequest/i, error.message)
    assert_equal NAME_ID, session['saml_uid']
  end

  def test_logout_rejects_a_different_user_without_clearing_session
    session = saml_session
    assert_raises(OmniAuth::Strategies::SAML::ValidationError) do
      strategy_request('slo', logout_request(name_id: 'other@example.test'), session: session, method: 'GET')
    end
    assert_equal NAME_ID, session['saml_uid']
  end

  def test_logout_does_not_propagate_external_relay_state
    %w[https://attacker.example.test/ //attacker.example.test/ javascript:alert(1)].each do |relay_state|
      session = saml_session
      result = strategy_request('slo', logout_request(relay_state: relay_state), session: session, method: 'GET')

      assert_equal 302, result.first
      assert_empty session
      assert_equal '/', redirect_query(result)['RelayState'], relay_state
    end
  end

  private

  def assert_rejected(xml, error_pattern, options: {})
    @authentication = nil
    session = {}
    result = authenticate(xml, options: options, session: session)

    assert_equal 401, result.first
    assert_nil @authentication
    assert_nil session['saml_uid']
    assert_match error_pattern, @failure.message
  end

  def unsigned_attacker_assertion(id: '_unsigned_attacker_assertion')
    xml = response_xml(signed: false).gsub(NAME_ID, 'attacker@example.test')
    assertion = REXML::Document.new(xml).root.elements['saml:Assertion']
    assertion.attributes['ID'] = id
    assertion
  end

  def redirect_query(result)
    Rack::Utils.parse_query(URI.parse(result[1]['Location']).query)
  end
end
