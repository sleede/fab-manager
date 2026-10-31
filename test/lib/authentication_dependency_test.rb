# frozen_string_literal: true

require 'test_helper'
require 'jwt'
require 'bcrypt'
require 'base64'

class AuthenticationDependencyTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    travel_to Time.utc(2030, 1, 1, 12)
    @key = 'synthetic-signing-key-for-local-regression-tests'
    @claims = { 'sub' => 'synthetic-member', 'iss' => 'https://issuer.example.test',
                'aud' => 'fab-manager-test', 'exp' => 5.minutes.from_now.to_i }
  end

  teardown do
    travel_back
  end

  test 'signed JWTs round trip with explicit algorithms and claims' do
    token = JWT.encode(@claims, @key, 'HS256')
    options = { algorithms: ['HS256'], verify_iss: true, iss: @claims['iss'], verify_aud: true, aud: @claims['aud'] }
    claims, header = JWT.decode(token, @key, true, options)
    assert_equal @claims, claims
    assert_equal 'HS256', header.fetch('alg')
  end

  test 'JWT rejects altered signatures unexpected algorithms and unsigned tokens' do
    token = JWT.encode(@claims, @key, 'HS256')
    assert_raises(JWT::DecodeError) { JWT.decode(token, 'wrong-local-key', true, algorithms: ['HS256']) }
    parts = token.split('.')
    parts[1] = Base64.urlsafe_encode64(JSON.generate(@claims.merge('sub' => 'other-member')), padding: false)
    assert_raises(JWT::DecodeError) { JWT.decode(parts.join('.'), @key, true, algorithms: ['HS256']) }
    token = JWT.encode(@claims, @key, 'HS384')
    assert_raises(JWT::DecodeError) { JWT.decode(token, @key, true, algorithms: ['HS256']) }
    unsigned = JWT.encode(@claims, nil, 'none')
    assert_raises(JWT::DecodeError) { JWT.decode(unsigned, @key, true, algorithms: ['HS256']) }
  end

  test 'JWT rejects expired tokens and mismatching required issuer and audience' do
    expired = JWT.encode(@claims.merge('exp' => 1.minute.ago.to_i), @key, 'HS256')
    assert_raises(JWT::ExpiredSignature) { JWT.decode(expired, @key, true, algorithms: ['HS256']) }
    token = JWT.encode(@claims, @key, 'HS256')
    assert_raises(JWT::InvalidIssuerError) do
      JWT.decode(token, @key, true, algorithms: ['HS256'], verify_iss: true, iss: 'other-issuer')
    end
    assert_raises(JWT::InvalidAudError) do
      JWT.decode(token, @key, true, algorithms: ['HS256'], verify_aud: true, aud: 'other-audience')
    end
  end

  test 'JWT verification rejects a nil HMAC key with a decode error' do
    token = JWT.encode(@claims, @key, 'HS256')
    assert_raises(JWT::DecodeError) { JWT.decode(token, nil, true, algorithms: ['HS256']) }
  end

  test 'JWT verification rejects a correctly signed token using an empty HMAC key' do
    # Construct the empty-key fixture without relying on the encoder accepting an unsafe key.
    message = [Base64.urlsafe_encode64(JSON.generate('alg' => 'HS256', 'typ' => 'JWT'), padding: false),
               Base64.urlsafe_encode64(JSON.generate(@claims), padding: false)].join('.')
    signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest('sha256', '', message), padding: false)
    assert_raises(JWT::DecodeError) { JWT.decode("#{message}.#{signature}", '', true, algorithms: ['HS256']) }
  end

  test 'OAuth2 exchanges a synthetic authorization code and preserves the signed access token' do
    token = JWT.encode(@claims, @key, 'HS256')
    stub_request(:post, 'https://oauth.example.test/token')
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                 body: JSON.generate(access_token: token, token_type: 'bearer', expires_in: 300))
    client = OAuth2::Client.new('local-client', 'local-secret', site: 'https://oauth.example.test', token_url: '/token')
    result = client.auth_code.get_token('synthetic-code', redirect_uri: 'https://app.example.test/users/auth/callback')
    assert_equal token, result.token
    assert_equal @claims, JWT.decode(result.token, @key, true, algorithms: ['HS256']).first
    assert_requested(:post, 'https://oauth.example.test/token', times: 1)
  end

  test 'Devise accepts legacy bcrypt hashes and rejects an incorrect password' do
    fixture = JSON.parse(File.read(Rails.root.join('test/fixtures/files/dependencies/legacy_bcrypt.json')))
    user = users(:user2)
    user.encrypted_password = fixture.fetch('hash')
    assert user.valid_password?(fixture.fetch('password'))
    assert_not user.valid_password?('incorrect-synthetic-password')
  end

  test 'Devise creates a usable bcrypt hash with its configured password settings' do
    user = users(:user2)
    user.password = 'Synthetic-new-password-42!'
    assert user.valid_password?('Synthetic-new-password-42!')
    assert_not user.valid_password?('Synthetic-new-password-43!')
    assert BCrypt::Password.new(user.encrypted_password).is_password?('Synthetic-new-password-42!')
  end
end
