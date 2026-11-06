# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'minitest/mock'
require 'addressable/template'

class UploadDependencyTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    @directory = Dir.mktmpdir('fab-manager-upload-')
    @root = File.join(@directory, 'public')
    FileUtils.mkdir_p(@root)
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test 'project images retain original dimensions generated versions URLs and removal' do
    uploader = local_uploader(ProjectImage.new(id: 900_001))
    File.open(image('project.png')) { |file| uploader.store!(file) }
    assert_equal [1600, 900], uploader.dimensions
    assert_equal 1000, MiniMagick::Image.open(uploader.large.path).width
    assert_equal 700, MiniMagick::Image.open(uploader.medium.path).width
    assert_match %r{/uploads/project_image/900001/project_image.png\z}, uploader.url
    paths = [uploader.path, uploader.large.path, uploader.medium.path]
    uploader.remove!
    paths.each { |stored| assert_not File.exist?(stored) }
  end

  test 'avatars produce configured sizes and support replacement' do
    uploader = local_uploader(UserAvatar.new(id: 900_002))
    File.open(image('first.png')) { |file| uploader.store!(file) }
    { normal: 140, small: 80, tiny: 40 }.each do |version, width|
      assert_equal width, MiniMagick::Image.open(uploader.versions.fetch(version).path).width
    end
    previous_bytes = File.binread(uploader.path)
    File.open(image('second.png', 'red')) { |file| uploader.store!(file) }
    assert_not_equal previous_bytes, File.binread(uploader.path)
  end

  test 'image uploaders reject executable extensions and disguised PDF content' do
    uploader = local_uploader(UserAvatar.new(id: 900_003), processing: false)
    assert_raises(CarrierWave::IntegrityError) do
      File.open(write_file('payload.exe', 'not an image')) { |file| uploader.cache!(file) }
    end
    path = write_file('document.jpg', "%PDF-1.4\nsynthetic document\n")
    File.open(path) do |file|
      upload = CarrierWave::SanitizedFile.new(tempfile: file, filename: 'document.jpg', content_type: 'image/jpeg')
      assert_raises(CarrierWave::IntegrityError) { uploader.cache!(upload) }
    end
  end

  test 'supporting documents retain bytes safe storage and removal' do
    uploader = local_uploader(SupportingDocumentFile.new(id: 900_004), processing: false)
    bytes = "%PDF-1.4\nsynthetic attachment\n"
    File.open(write_file('resume.pdf', bytes)) { |file| uploader.store!(file) }
    assert_equal bytes, File.binread(uploader.path)
    assert_equal 'resume.pdf', uploader.file.filename
    assert uploader.path.start_with?(File.join(@directory, 'supporting_document_files'))
    stored = uploader.path
    uploader.remove!
    assert_not File.exist?(stored)
  end

  test 'configured model validators reject oversized image CAD and document files' do
    [ProjectImage.new, ProjectCao.new, SupportingDocumentFile.new].each do |record|
      validator = record.class.validators_on(:attachment).find { |item| item.is_a?(FileSizeValidator) }
      maximum = validator.options.fetch(:maximum)
      path = write_file('oversize.pdf', "%PDF-1.4\n")
      File.open(path, 'ab') { |file| file.truncate(maximum + 1) }
      # Use a real cached PDF; MIME policy and per-model size policy are separate checks.
      uploader = local_uploader(SupportingDocumentFile.new, processing: false)
      File.open(path) { |file| uploader.cache!(file) }
      validator.validate_each(record, :attachment, uploader)
      assert record.errors.of_kind?(:attachment, :size_too_big)
    end
  end

  test 'CAD uploaders preserve configured extensions MIME and generated URLs' do
    original = Setting.method(:get)
    values = { 'allowed_cad_extensions' => 'stl', 'allowed_cad_mime_types' => 'text/plain application/octet-stream' }
    Setting.stub(:get, ->(name, *args) { values.fetch(name) { original.call(name, *args) } }) do
      uploader = local_uploader(ProjectCao.new(id: 900_005), processing: false)
      path = write_file('part.stl', "solid synthetic\nendsolid synthetic\n")
      File.open(path) { |file| uploader.store!(file) }
      assert_match %r{/uploads/project_cao/900005/part.stl\z}, uploader.url
      assert_equal File.binread(path), File.binread(uploader.path)
      assert_raises(CarrierWave::IntegrityError) do
        File.open(write_file('part.exe', 'binary')) { |file| uploader.cache!(file) }
      end
    end
  end

  test 'remote uploads reject loopback before making an HTTP connection' do
    uploader = local_uploader(SupportingDocumentFile.new, processing: false)
    url = 'http://127.0.0.1/never-download.pdf'
    stub_request(:get, url).to_return(body: "%PDF-1.4\n")
    assert_raises(CarrierWave::DownloadError) { uploader.download!(url) }
    assert_not_requested(:get, url)
  end

  test 'Addressable normalizes parent segments consistently above the root' do
    uri = Addressable::URI.parse('https://example.test/../../public/x/../../secret')
    assert_equal '/secret', uri.normalize.path
    assert_equal 'https://example.test/secret', uri.normalize.to_s
  end

  test 'Addressable round trips encoded paths and query values' do
    template = Addressable::Template.new('https://example.test/{path}{?q}')
    uri = template.expand('path' => 'cafe/read me', 'q' => 'a&b')
    assert_equal 'https://example.test/cafe%2Fread%20me?q=a%26b', uri.to_s
    assert_equal 'cafe/read me', template.extract(uri).fetch('path')
    assert_equal 'a&b', template.extract(uri).fetch('q')
    assert_nil template.extract('https://other.test/file')
  end

  private

  def local_uploader(record, processing: true)
    uploader = record.attachment
    uploader.root = @root
    uploader.enable_processing = processing
    uploader.versions.each_value do |version|
      version.root = @root
      version.enable_processing = processing
    end
    uploader
  end

  def image(name, color = 'navy')
    path = File.join(@directory, name)
    assert system('convert', '-size', '1600x900', "xc:#{color}", path)
    path
  end

  def write_file(name, bytes)
    path = File.join(@directory, name)
    File.binwrite(path, bytes)
    path
  end
end
