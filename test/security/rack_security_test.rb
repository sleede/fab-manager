# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'rack'
require 'rack/query_parser'
require 'rack/session/pool'
require 'tmpdir'
require 'fileutils'

# Exercise the HTTP boundary behavior used by Rails and its Rack middleware.
# Run without services: bundle exec ruby -Itest test/security/rack_security_test.rb
class RackSecurityTest < Minitest::Test
  def test_parses_nested_form_fields_and_cookie_values
    fields = Rack::Utils.parse_nested_query('member[name]=Local+Member&member[tags][]=one&member[tags][]=two')

    assert_equal({ 'name' => 'Local Member', 'tags' => %w[one two] }, fields['member'])
    assert_equal({ '__Host-session' => 'trusted', '%5F%5FHost-session' => 'other', 'label' => 'Local Member' },
                 Rack::Utils.parse_cookies_header('__Host-session=trusted; %5F%5FHost-session=other; label=Local+Member'))
  end

  def test_bounds_query_bytes_and_parameter_counts
    parser = Rack::QueryParser.make_default(65_536, 8, bytesize_limit: 64, params_limit: 3)

    assert_equal({ 'a' => '1', 'b' => '2' }, parser.parse_query('a=1&b=2'))
    assert_raises(Rack::QueryParser::ParamsTooDeepError) { parser.parse_query("a=#{'x' * 64}") }
    ['a=1&b=2&c=3&d=4', 'a=1;b=2;c=3;d=4'].each do |query|
      assert_raises(Rack::QueryParser::ParamsTooDeepError) { parser.parse_query(query) }
    end
  end

  def test_rejects_conflicting_parameter_types_and_excessive_depth
    parser = Rack::QueryParser.make_default(65_536, 3)

    assert_raises(Rack::QueryParser::ParameterTypeError) { parser.parse_nested_query('a=one&a[b]=two') }
    assert_raises(Rack::QueryParser::ParamsTooDeepError) { parser.parse_nested_query('a[b][c][d]=value') }
  end

  def test_accepts_normal_multipart_fields_and_file_uploads
    body = "--local\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nLocal file\r\n" \
           "--local\r\nContent-Disposition: form-data; name=\"file\"; filename=\"example.txt\"\r\n" \
           "Content-Type: text/plain\r\n\r\nfixture content\r\n--local--\r\n"
    params = parse_multipart(body)

    assert_equal 'Local file', params['title']
    assert_equal 'example.txt', params['file'][:filename]
    assert_equal 'text/plain', params['file'][:type]
    assert_equal 'fixture content', params['file'][:tempfile].read
  ensure
    params&.dig('file', :tempfile)&.close!
  end

  # GHSA-p8x9-v4hv-2w4g: an empty first boundary must not hide a second one.
  def test_rejects_ambiguous_multipart_boundaries
    body = "--local\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nvalue\r\n--local--\r\n"
    ['boundary=first; boundary=local', 'boundary=; boundary=local',
     'boundary=""; boundary=local', 'boundary=local; boundary*=UTF-8\'\'other'].each do |parameters|
      assert_raises(EOFError, parameters) { parse_multipart(body, "multipart/form-data; #{parameters}") }
    end
  end

  def test_unfolds_multipart_filenames_without_preserving_crlf
    body = "--local\r\nContent-Disposition: form-data; name=\"file\"; filename=\"local\r\n example.txt\"\r\n" \
           "Content-Type: text/plain\r\n\r\nfixture\r\n--local--\r\n"
    params = parse_multipart(body)

    assert_equal 'local example.txt', params['file'][:filename]
    assert_empty params['file'][:filename].scan(/[\r\n]/)
  ensure
    params&.dig('file', :tempfile)&.close!
  end

  def test_rejects_bounded_multipart_part_overflow
    previous = Rack::Utils.multipart_total_part_limit
    Rack::Utils.multipart_total_part_limit = 3
    body = (1..4).map { |i| "--local\r\nContent-Disposition: form-data; name=\"field#{i}\"\r\n\r\nvalue\r\n" }.join
    body += "--local--\r\n"

    assert_raises(Rack::Multipart::MultipartTotalPartLimitError) { parse_multipart(body) }
  ensure
    Rack::Utils.multipart_total_part_limit = previous
  end

  def test_static_files_preserve_headers_for_encoded_and_dot_segment_paths
    with_static_files do |request|
      ['/assets/private/report.txt', '/assets/%70rivate/report.txt',
       '/assets/other/../private/report.txt'].each do |url|
        response = request.get(url)

        assert_equal 200, response.status, url
        assert_equal 'fixture', response.body, url
        assert_equal 'no-store', response['Cache-Control'], url
      end
    end
  end

  def test_static_prefix_does_not_expose_a_sibling_directory
    with_static_files do |request|
      response = request.get('/assets-backup/private.txt')

      assert_equal 404, response.status
      assert_equal 'not found', response.body
    end
  end

  def test_file_ranges_and_error_lengths_remain_consistent
    Dir.mktmpdir('rack-files') do |directory|
      File.write(File.join(directory, 'fixture.txt'), 'fixture')
      request = Rack::MockRequest.new(Rack::Files.new(directory))
      partial = request.get('/fixture.txt', 'HTTP_RANGE' => 'bytes=0-2')
      missing = request.get('/missing.txt')

      assert_equal 206, partial.status
      assert_equal 'fix', partial.body
      assert_equal missing.body.bytesize, missing['Content-Length'].to_i
    end
  end

  def test_logout_invalidates_the_server_side_session
    application = lambda do |env|
      session = env['rack.session']
      case env['PATH_INFO']
      when '/login'
        session['member'] = 'local-member'
      when '/logout'
        session.clear
        env['rack.session.options'][:drop] = true
      end
      [200, { 'Content-Type' => 'text/plain' }, [session['member'] || 'anonymous']]
    end
    request = Rack::MockRequest.new(Rack::Session::Pool.new(application, httponly: true, same_site: :lax))
    signed_in = request.get('/login')
    cookie = signed_in['Set-Cookie'].split(';').first

    assert_includes signed_in['Set-Cookie'], 'HttpOnly'
    assert_includes signed_in['Set-Cookie'], 'SameSite=Lax'
    assert_equal 'local-member', request.get('/', 'HTTP_COOKIE' => cookie).body
    assert_equal 'anonymous', request.get('/logout', 'HTTP_COOKIE' => cookie).body
    assert_equal 'anonymous', request.get('/', 'HTTP_COOKIE' => cookie).body
  end

  private

  def parse_multipart(body, content_type = 'multipart/form-data; boundary=local')
    env = Rack::MockRequest.env_for('/', method: 'POST', input: body, 'CONTENT_TYPE' => content_type)
    Rack::Multipart.parse_multipart(env)
  end

  def with_static_files
    Dir.mktmpdir('rack-static') do |directory|
      FileUtils.mkdir_p(File.join(directory, 'assets/private'))
      FileUtils.mkdir_p(File.join(directory, 'assets-backup'))
      File.write(File.join(directory, 'assets/private/report.txt'), 'fixture')
      File.write(File.join(directory, 'assets-backup/private.txt'), 'private fixture')
      fallback = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['not found']] }
      application = Rack::Static.new(fallback, root: directory, urls: ['/assets'],
                                               header_rules: [['/assets/private', { 'Cache-Control' => 'no-store' }]])

      yield Rack::MockRequest.new(application)
    end
  end
end
