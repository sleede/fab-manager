# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'
require 'websocket/driver'
require 'action_cable'
require 'action_cable/connection/web_socket'

class HttpDependencyTest < ActionDispatch::IntegrationTest
  include WebMock::API

  setup do
    @previous_config = %i[base_uri app_secret httparty_verify httparty_verify_peer].index_with do |key|
      Openlab.config.public_send(key)
    end
    @previous_options = Openlab::Client.default_options.deep_dup
    Openlab.config.base_uri = 'https://openlab.example.test'
    Openlab.config.app_secret = 'local-openlab-secret'
    Openlab.config.httparty_verify = true
    Openlab.config.httparty_verify_peer = true
    @client = Openlab::Client.new(app_secret: 'local-openlab-secret')
    @projects = Openlab::Projects.new(@client)
    @authorization = { 'Authorization' => 'Token token=local-openlab-secret' }
  end

  teardown do
    @previous_config.each { |key, value| Openlab.config.public_send("#{key}=", value) }
    Openlab::Client.default_options.replace(@previous_options)
    Warden.test_reset!
  end

  test 'real Openlab search encodes query parameters and retains configured credentials' do
    stub_request(:get, 'https://openlab.example.test/api/v1/projects')
      .with(query: { q: 'café & bois', page: '2', per_page: '10' }, headers: @authorization)
      .to_return(body: '{"projects":[]}', headers: { 'Content-Type' => 'application/json' })
    response = @projects.search('café & bois', page: 2, per_page: 10)
    assert_equal({ 'projects' => [] }, response.parsed_response)
    assert_equal 200, response.code
  end

  test 'real Openlab project writes retain their methods and nested form parameters' do
    url = 'https://openlab.example.test/api/v1/projects'
    stub_request(:post, url)
      .with(body: { project: { title: 'Projet Montréal' } }, headers: @authorization)
      .to_return(status: 201, body: '{"id":7}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:patch, "#{url}/7")
      .with(body: { project: { title: 'Updated project' } }, headers: @authorization)
      .to_return(body: '{"id":7}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:delete, "#{url}/7")
      .with(headers: @authorization).to_return(status: 204)
    assert_equal 201, @projects.create(title: 'Projet Montréal').code
    assert_equal({ 'id' => 7 }, @projects.update(7, title: 'Updated project').parsed_response)
    assert_equal 204, @projects.destroy(7).code
  end

  test 'an absolute different-host path is rejected before credentials are forwarded' do
    url = 'https://unintended.example.test/never-send'
    stub_request(:get, url)
      .with(headers: @authorization).to_return(body: '{}')
    error = assert_raises(StandardError) { @client.get(url) }
    assert_equal 'HTTParty::UnsafeURIError', error.class.name
    assert_not_requested(:get, url)
  end

  test 'relative same-host redirects preserve the configured Openlab request' do
    stub_request(:get, 'https://openlab.example.test/api/v1/projects')
      .with(query: { q: 'wood' }, headers: @authorization)
      .to_return(status: 302, headers: { 'Location' => '/api/v1/redirected' })
    stub_request(:get, 'https://openlab.example.test/api/v1/redirected')
      .with(headers: @authorization)
      .to_return(body: '{"projects":[]}', headers: { 'Content-Type' => 'application/json' })
    assert_equal({ 'projects' => [] }, @projects.search('wood').parsed_response)
    assert_requested(:get, 'https://openlab.example.test/api/v1/redirected', times: 1)
  end

  test 'BOM JSON parses while the raw response body remains unchanged' do
    bytes = "\xEF\xBB\xBF{\"projects\":[]}".b
    stub_request(:get, 'https://openlab.example.test/api/v1/projects')
      .with(query: { q: 'bom' })
      .to_return(body: bytes, headers: { 'Content-Type' => 'application/json' })
    response = @projects.search('bom')
    assert_equal({ 'projects' => [] }, response.parsed_response)
    assert_equal bytes, response.body.b
  end

  test 'text and XML parser contracts preserve raw bodies' do
    stub_request(:get, 'https://http.example.test/text')
      .to_return(body: 'plain text', headers: { 'Content-Type' => 'text/plain' })
    stub_request(:get, 'https://http.example.test/xml')
      .to_return(body: '<result><value>ok</value></result>', headers: { 'Content-Type' => 'application/xml' })
    text = HTTParty.get('https://http.example.test/text')
    xml = HTTParty.get('https://http.example.test/xml')
    assert_equal 'plain text', text.parsed_response
    assert_equal 'plain text', text.body
    assert_equal({ 'result' => { 'value' => 'ok' } }, xml.parsed_response)
  end

  test 'HTTP failures and transport timeouts retain their distinct outcomes' do
    url = 'https://openlab.example.test/api/v1/projects'
    stub_request(:get, url)
      .with(query: { q: 'unavailable' })
      .to_return(status: 503, body: '{"error":"unavailable"}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, url)
      .with(query: { q: 'timeout' }).to_timeout
    response = @projects.search('unavailable')
    assert_equal 503, response.code
    assert_equal 'unavailable', response.parsed_response.fetch('error')
    assert_raises(Timeout::Error) { @projects.search('timeout') }
  end

  test 'the actual Openlab worker preserves the project deletion request' do
    original = Setting.method(:get)
    settings = ->(name, *args) { name == 'openlab_app_secret' ? 'local-openlab-secret' : original.call(name, *args) }
    url = 'https://openlab.example.test/api/v1/projects/9'
    stub_request(:delete, url)
      .with(headers: @authorization).to_return(status: 204)
    Setting.stub(:get, settings) { OpenlabWorker.new.perform('destroy', 9) }
    assert_requested(:delete, url, times: 1)
  end

  test 'the actual HTTP connection adapter retains TLS peer verification' do
    connection = HTTParty::ConnectionAdapter.call(URI('https://openlab.example.test'), Openlab::Client.default_options)
    assert connection.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, connection.verify_mode
    assert_equal true, Openlab::Client.default_options.fetch(:verify)
    assert_equal true, Openlab::Client.default_options.fetch(:verify_peer)
  end

  test 'the real Openlab controller preserves raw JSON and its unavailable-service response' do
    original = Setting.method(:get)
    settings = ->(name, *args) { name == 'openlab_app_secret' ? 'local-openlab-secret' : original.call(name, *args) }
    Setting.stub(:get, settings) do
      stub_request(:get, 'https://openlab.example.test/api/v1/projects')
        .with(query: { q: 'wood', page: '1', per_page: '5' }, headers: @authorization)
        .to_return(body: '{"projects":[{"id":7}]}', headers: { 'Content-Type' => 'application/json' })
      get '/api/openlab_projects', params: { q: 'wood', page: 1, per_page: 5 }
      assert_response :success
      assert_equal({ 'projects' => [{ 'id' => 7 }] }, response.parsed_body)

      stub_request(:get, 'https://openlab.example.test/api/v1/projects')
        .with(query: { q: 'offline', page: '1', per_page: '5' }).to_raise(Errno::ECONNREFUSED)
      get '/api/openlab_projects', params: { q: 'offline', page: 1, per_page: 5 }
      assert_equal({ 'errors' => ['service unavailable'] }, response.parsed_body)
    end
  end
end

class WebSocketDependencyTest < ActiveSupport::TestCase
  MemorySocket = Struct.new(:url, :written, :env) do
    def write(data)
      written << data
      data.bytesize
    end
  end

  EventTarget = Struct.new(:messages, :errors, :opened, :closed) do
    def on_open
      self.opened = true
    end

    def on_message(data)
      messages << data
    end

    def on_error(message)
      errors << message
    end

    def on_close(reason, code)
      self.closed = [reason, code]
    end
  end

  test 'real ActionCable negotiates the JSON subprotocol and exchanges UTF-8 text' do
    pair = cable_pair
    assert pair[:target].opened
    assert pair[:websocket].alive?
    assert_equal 'actioncable-v1-json', pair[:websocket].protocol
    pair[:client].text('{"message":"Montréal"}')
    pump(pair[:client_socket].written, pair[:cable])
    assert_equal ['{"message":"Montréal"}'], pair[:target].messages
    pair[:websocket].transmit('{"type":"welcome"}')
    pump(pair[:output], pair[:client])
    assert_equal ['{"type":"welcome"}'], pair[:received]
    assert_empty pair[:target].errors
  end

  test 'the ActionCable driver receives binary frames as binary strings' do
    pair = cable_pair
    bytes = "\x00\xFF\x03".b
    pair[:client].binary(bytes)
    pump(pair[:client_socket].written, pair[:cable])
    assert_kind_of String, pair[:target].messages.last
    assert_equal bytes, pair[:target].messages.last
    assert_equal Encoding::BINARY, pair[:target].messages.last.encoding
  end

  test 'ActionCable keeps its array transmit API with binary-string client messages' do
    pair = cable_pair
    pair[:websocket].transmit([0, 255, 3])
    pump(pair[:output], pair[:client])
    assert_kind_of String, pair[:received].last
    assert_equal "\x00\xFF\x03".b, pair[:received].last
    assert_equal Encoding::BINARY, pair[:received].last.encoding
  end

  test 'real driver ping pong and close complete without a socket or scheduler thread' do
    pair = cable_pair
    acknowledged = false
    pair[:client].ping('local-probe') { acknowledged = true }
    pump(pair[:client_socket].written, pair[:cable])
    pump(pair[:output], pair[:client])
    assert acknowledged
    pair[:websocket].close
    pump(pair[:output], pair[:client])
    pump(pair[:client_socket].written, pair[:cable])
    assert_equal :closed, pair[:client].state
    assert_not pair[:websocket].alive?
    assert_equal 1000, pair[:target].closed.last
  end

  test 'the real frame parser rejects a bounded message above its configured maximum' do
    env = websocket_env('dGhlIHNhbXBsZSBub25jZQ==')
    socket = MemorySocket.new('ws://cable.example.test/cable', [], env)
    driver = ::WebSocket::Driver.rack(socket, max_length: 8)
    errors = []
    driver.on(:error) { |error| errors << error.message }
    driver.start
    bytes = 'x' * 16
    mask = [1, 2, 3, 4]
    encoded = bytes.bytes.each_with_index.map { |byte, index| byte ^ mask[index % 4] }
    driver.parse([0x82, 0x80 | bytes.bytesize, *mask, *encoded].pack('C*'))
    assert_not_empty errors
  end

  test 'server driver reports malformed Host input without raising outside the protocol' do
    socket = MemorySocket.new(nil, [], {})
    driver = ::WebSocket::Driver.server(socket)
    errors = []
    driver.on(:connect) { driver.start }
    driver.on(:error) { |error| errors << error.message }
    assert_nothing_raised { driver.parse(server_request('[')) }
    assert_not_empty errors
  end

  test 'server driver rejects request headers above its bounded 32K limit' do
    socket = MemorySocket.new(nil, [], {})
    driver = ::WebSocket::Driver.server(socket)
    errors = []
    driver.on(:connect) { driver.start }
    driver.on(:error) { |error| errors << error.message }
    driver.parse(server_request('cable.example.test', 'a' * 33_000))
    assert_not_empty errors
  end

  private

  def cable_pair
    socket = MemorySocket.new('ws://cable.example.test/cable', [], {})
    client = ::WebSocket::Driver.client(socket, protocols: ['actioncable-v1-json'])
    received = []
    client.on(:message) { |event| received << event.data }
    client.start
    request = socket.written.shift
    key = request[/^Sec-WebSocket-Key: (.+)\r$/i, 1]
    output = []
    target = EventTarget.new([], [], false, nil)
    env = websocket_env(key)
    env['stream.send'] = lambda do |data|
      output << data
      data.bytesize
    end
    websocket = ActionCable::Connection::WebSocket.new(env, target, nil)
    websocket.rack_response
    pump(output, client)
    { client: client, client_socket: socket, websocket: websocket, cable: websocket.possible?,
      target: target, output: output, received: received }
  end

  def websocket_env(key)
    { 'REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/cable', 'PATH_INFO' => '/cable',
      'HTTP_HOST' => 'cable.example.test', 'HTTP_UPGRADE' => 'websocket', 'HTTP_CONNECTION' => 'Upgrade',
      'HTTP_SEC_WEBSOCKET_VERSION' => '13', 'HTTP_SEC_WEBSOCKET_KEY' => key,
      'HTTP_SEC_WEBSOCKET_PROTOCOL' => 'actioncable-v1-json', 'rack.url_scheme' => 'http' }
  end

  def pump(output, driver)
    output.shift(output.length).each { |bytes| driver.parse(bytes) }
  end

  def server_request(host, padding = nil)
    lines = ['GET /cable HTTP/1.1', "Host: #{host}", 'Upgrade: websocket', 'Connection: Upgrade',
             'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version: 13']
    lines << "X-Padding: #{padding}" if padding
    "#{lines.join("\r\n")}\r\n\r\n"
  end
end
