# frozen_string_literal: true

require 'test_helper'
require 'mail'
require 'net/imap'
require 'minitest/mock'

class MailDependencyTest < ActiveSupport::TestCase
  setup do
    @previous_delivery = ActionMailer::Base.delivery_method
    @previous_perform = ActionMailer::Base.perform_deliveries
    @previous_deliveries = ActionMailer::Base.deliveries.dup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.delivery_method = @previous_delivery
    ActionMailer::Base.perform_deliveries = @previous_perform
    ActionMailer::Base.deliveries.replace(@previous_deliveries)
  end

  test 'multipart mail retains UTF-8 subject text HTML and attachment bytes' do
    message = Mail.new
    message.from = 'Fablab <sender@example.test>'
    message.to = 'member@example.test'
    message.subject = 'Réservation à Montréal'
    message.text_part = Mail::Part.new(content_type: 'text/plain; charset=UTF-8', body: 'Votre réservation est confirmée.')
    message.html_part = Mail::Part.new(content_type: 'text/html; charset=UTF-8', body: '<p>Réservation confirmée.</p>')
    bytes = "%PDF-1.4\nsynthetic attachment\0\xFF\n".b
    message.attachments['resume.pdf'] = { mime_type: 'application/pdf', content: bytes }

    parsed = Mail.read_from_string(message.encoded)
    assert_equal 'Réservation à Montréal', parsed.subject
    assert_equal ['member@example.test'], parsed.to
    assert_includes parsed.text_part.decoded, 'réservation'
    assert_includes parsed.html_part.decoded, 'confirmée'
    assert_equal bytes, parsed.attachments['resume.pdf'].decoded
  end

  test 'legacy MIME charset and quoted printable body survive parsing' do
    source = "From: sender@example.test\r\nTo: member@example.test\r\n" \
             "Content-Type: text/plain; charset=ISO-8859-1\r\n" \
             "Content-Transfer-Encoding: quoted-printable\r\n\r\ncaf=E9"
    message = Mail.read_from_string(source)
    assert_equal 'iso-8859-1', message.charset.downcase
    assert_equal 'café', message.body.decoded.force_encoding('ISO-8859-1').encode('UTF-8')
    assert_equal message.body.decoded.b, Mail.read_from_string(message.encoded).body.decoded.b
  end

  test 'encoded word decoders retain surrounding literal header text' do
    assert_equal 'prefix Cafe suffix', Mail::Utilities.q_value_decode('prefix =?UTF-8?Q?Cafe?= suffix')
    assert_equal 'prefix Cafe suffix', Mail::Utilities.b_value_decode('prefix =?UTF-8?B?Q2FmZQ==?= suffix')
  end

  test 'valid display names preserve the actual address and malformed addresses raise' do
    address = Mail::Address.new('Member Example <member@example.test>')
    assert_equal 'member@example.test', address.address
    assert_equal 'Member Example', address.display_name
    assert_raises(Mail::Field::IncompleteParseError) { Mail::Address.new('broken <address').address }
  end

  test 'account creation mail renders and delivers through the test adapter only' do
    user = users(:user2)
    user.email = 'member@example.test'
    message = with_static_packs { UsersMailer.notify_user_account_created(user, 'Synthetic-password-123!').deliver_now }
    assert_equal ['member@example.test'], message.to
    assert_not_empty message.subject
    assert_not_empty message.body.encoded
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_instance_of Mail::TestMailer, message.delivery_method
  end

  test 'Devise reset instructions render their synthetic token through the test adapter' do
    user = users(:user2)
    user.email = 'member@example.test'
    message = with_static_packs { OverwrittenDeviseMailer.reset_password_instructions(user, 'synthetic-reset-token').deliver_now }
    assert_equal ['member@example.test'], message.to
    assert_includes message.body.decoded, 'synthetic-reset-token'
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_instance_of Mail::TestMailer, message.delivery_method
  end

  test 'the real user-created notification template renders and uses test delivery' do
    notification = notifications('notification_1')
    notification.receiver.email = 'admin@example.test'
    message = with_static_packs { NotificationsMailer.send_mail_by(notification).deliver_now }
    assert_equal ['admin@example.test'], message.to
    assert_not_empty message.subject
    assert_not_empty message.body.encoded
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_instance_of Mail::TestMailer, message.delivery_method
  end

  test 'IMAP parser accepts bounded server responses and rejects malformed input without connecting' do
    parser = Net::IMAP::ResponseParser.new
    exists = parser.parse("* 2 EXISTS\r\n")
    assert_equal 'EXISTS', exists.name
    assert_equal 2, exists.data
    fetch = parser.parse("* 1 FETCH (UID 42 BODY[] {5}\r\nhello)\r\n")
    assert_equal 42, fetch.data.attr.fetch('UID')
    assert_equal 'hello', fetch.data.attr.fetch('BODY[]')
    assert_raises(Net::IMAP::ResponseParseError) { parser.parse("* 1 FETCH (UID\r\n") }
  end

  private

  # The mail layout embeds a compiled logo. Webpack output is a build artifact, not the behavior under
  # test, and the test-environment compile is not available in a clean checkout.
  def with_static_packs(&)
    Webpacker.instance.manifest.stub(:lookup!, ->(name, *) { "/packs-test/#{name}" }, &)
  end
end
