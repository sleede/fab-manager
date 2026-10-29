# frozen_string_literal: true

require 'test_helper'

# Exercise the same sanitizer and allowlists used by descriptions, orders and PDFs.
class HtmlSanitizationTest < ActiveSupport::TestCase
  test 'descriptions retain permitted formatting and inline styles' do
    html = '<p style="color: red; font-weight: bold"><strong>Workshop</strong> &amp; tools</p>'
    fragment = sanitized_fragment(html)

    assert_equal 'Workshop & tools', fragment.text
    assert_equal 'Workshop', fragment.at_css('p strong').text
    assert_match(/color:\s*red/, fragment.at_css('p')['style'])
    assert_match(/font-weight:\s*bold/, fragment.at_css('p')['style'])
  end

  test 'descriptions remove active content and dangerous style declarations' do
    html = '<p onclick="alert(1)" style="color: red; position: fixed; background-image: url(https://example.invalid/image)">' \
           'Workshop<script>alert(1)</script></p><iframe src="https://example.invalid/"></iframe>'
    fragment = sanitized_fragment(html)

    assert_empty fragment.css('script, iframe, [onclick]')
    assert_match(/color:\s*red/, fragment.at_css('p')['style'])
    assert_no_dangerous_css(fragment.at_css('p')['style'])
  end

  test 'descriptions do not allow SVG references or style elements' do
    html = '<svg><use href="/uploads/untrusted.svg#shape"></use>' \
           '<feImage href="https://example.invalid/image"></feImage></svg>' \
           '<style>body { position: fixed }</style><p>Workshop</p>'
    fragment = sanitized_fragment(html)

    assert_empty fragment.css('svg, use, feImage, style')
    assert_equal 'Workshop', fragment.at_css('p').text
  end

  test 'descriptions keep ordinary links but reject executable link protocols' do
    fragment = sanitized_fragment('<a href="https://example.invalid/workshop">Workshop</a>')
    assert_equal 'https://example.invalid/workshop', fragment.at_css('a')['href']

    ['javascript:alert(1)', 'java&#9;script:alert(1)', 'javascript&#58alert(1)'].each do |url|
      fragment = sanitized_fragment("<a href=\"#{url}\">Workshop</a>")
      assert_nil fragment.at_css('a')['href'], "Executable link survived: #{url}"
      assert_equal 'Workshop', fragment.text
    end
  end

  test 'bad CSS URLs cannot hide forbidden declarations inside allowed functions' do
    # GHSA-pq4g-8rxf-4g29: browsers end the bad URL after the escaped backslash.
    # Use a small local string; no browser or external resource is contacted.
    backslash = '\\'
    %w[calc rgb].each do |function|
      css = "width:#{function}(url(x\"#{backslash * 2})); position:fixed; x:)); color:red"
      style = sanitized_fragment("<p style=\"#{ERB::Util.html_escape(css)}\">Workshop</p>").at_css('p')['style']

      assert_no_match(/position\s*:/i, style.to_s)
      assert_match(/color:\s*red/, style)
    end
  end

  test 'inline styles tolerate adjacent comments and retain Unicode text' do
    css = "#{'/**/' * 500}color:red"
    fragment = sanitized_fragment("<p style=\"#{css}\">Atelier \u00e9lectronique</p>")

    assert_equal "Atelier \u00e9lectronique", fragment.text
    assert_match(/color:\s*red/, fragment.at_css('p')['style'])
  end

  test 'order withdrawal instructions retain their narrower formatting and link allowlist' do
    Setting.set('store_withdrawal_instructions', '<h3>Collection</h3><p style="color:red"><strong>Bring ID</strong> ' \
                                                 '<a href="https://example.invalid/help" target="_blank" rel="noopener">Help</a></p>')
    fragment = Nokogiri::HTML.fragment(Orders::OrderService.withdrawal_instructions(Order.new(state: 'cart')))

    assert_equal 'Collection', fragment.at_css('h3').text
    assert_equal 'Bring ID', fragment.at_css('strong').text
    assert_equal 'https://example.invalid/help', fragment.at_css('a')['href']
    assert_equal '_blank', fragment.at_css('a')['target']
    assert_equal 'noopener', fragment.at_css('a')['rel']
    assert_nil fragment.at_css('p')['style']
  end

  test 'order withdrawal instructions strip scripts and executable links' do
    Setting.set('store_withdrawal_instructions', '<p onclick="alert(1)">Collection</p><script>alert(1)</script>' \
                                                 '<a href="java&#9;script:alert(1)">Help</a>' \
                                                 '<svg><use href="/uploads/untrusted.svg#shape"></use></svg>')
    fragment = Nokogiri::HTML.fragment(Orders::OrderService.withdrawal_instructions(Order.new(state: 'cart')))

    assert_empty fragment.css('script, svg, use, [onclick]')
    assert_nil fragment.at_css('a')['href']
    assert_equal 'Collection', fragment.at_css('p').text
  end

  test 'invoice and schedule HTML retain PDF formatting and remove active content' do
    html = '<p><b>Collection</b><br><u>Bring ID</u> <i>please</i></p>' \
           '<img src="https://example.invalid/image" onerror="alert(1)"><script>alert(1)</script>'

    [Pdf::Invoice, Pdf::PaymentSchedule].each do |renderer|
      fragment = Nokogiri::HTML.fragment(renderer.allocate.send(:parse_html, html))

      assert_equal %w[b br u i], fragment.css('*').map(&:name), renderer.name
      assert_equal 'Collection', fragment.at_css('b').text
      assert_equal 'Bring ID', fragment.at_css('u').text
      assert_equal 'please', fragment.at_css('i').text
    end
  end

  test 'invoice PDF renders sanitized custom information' do
    Setting.set('invoice_text', '<b>Local collection</b><br><i>Bring ID</i><img src="https://example.invalid/image">')
    Setting.set('invoice_legals', '<u>Test workshop</u>')
    invoice = sample_reservation_invoice(users(:user2), User.find_by!(username: 'admin'))

    assert_invoice_pdf(invoice) do |lines|
      assert_includes lines.join("\n"), 'Local collection'
      assert_includes lines.join("\n"), 'Bring ID'
      assert_includes lines.join("\n"), 'Test workshop'
    end
  end

  test 'payment schedule PDF renders sanitized custom information' do
    Setting.set('invoice_text', '<b>Local collection</b><br><i>Bring ID</i><img src="https://example.invalid/image">')
    Setting.set('invoice_legals', '<u>Test workshop</u>')
    schedule = payment_schedules('payment_schedule_13')
    pdf = Pdf::PaymentSchedule.new(schedule).render
    reader = PDF::Reader.new(StringIO.new(pdf))
    text = reader.pages.map(&:text).join("\n")

    assert_includes text, 'Local collection'
    assert_includes text, 'Bring ID'
    assert_includes text, 'Test workshop'
  end

  private

  def sanitized_fragment(html)
    Nokogiri::HTML.fragment(ActionController::Base.helpers.sanitize(html))
  end

  def assert_no_dangerous_css(style)
    assert_no_match(/position\s*:|url\s*\(|expression\s*\(/i, style.to_s)
  end
end
