# frozen_string_literal: true

# provide checksums for archiving control
class Checksum
  class << self
    def code
      dir = Dir.pwd

      files = children_files("#{dir}/*")
              .concat(children_files("#{dir}/app/**/*"))
              .concat(children_files("#{dir}/bin/**/*"))
              .concat(children_files("#{dir}/config/**/*"))
              .concat(children_files("#{dir}/db/**/*"))
              .concat(children_files("#{dir}/doc/**/*"))
              .concat(children_files("#{dir}/docker/**/*"))
              .concat(children_files("#{dir}/lib/**/*"))
              .concat(children_files("#{dir}/node_modules/**/*"))
              .concat(children_files("#{dir}/plugins/**/*"))
              .concat(children_files("#{dir}/provision/**/*"))
              .concat(children_files("#{dir}/scripts/**/*"))
              .concat(children_files("#{dir}/test/**/*"))
              .concat(children_files("#{dir}/vendor/**/*"))

      content = files.map { |f| File.read(f) }.join

      sha256 = Digest::SHA256.new
      sha256.hexdigest content
    end

    def file(path)
      return unless File.exist?(path)

      content = File.read(path)

      sha256 = Digest::SHA256.new
      sha256.hexdigest content
    end

    private

    def children_files(path)
      Dir[path].reject { |f| File.directory?(f) }
    end
  end
end
