module ContentTypeValidationFromFileContent
  extend ActiveSupport::Concern

  # overrides carrierwave methods to do a REAL mime type check based on content and not based on extension

  included do
    private
      def check_content_type_whitelist!(new_file)
        content_type = Marcel::MimeType.for Pathname.new(new_file.file)

        if content_type_whitelist && content_type && !whitelisted_content_type?(content_type)
          raise CarrierWave::IntegrityError,
                I18n.translate(:'errors.messages.content_type_whitelist_error',
                              content_type: content_type,
                              allowed_types: Array(content_type_whitelist).join(', '))
        end
      end

      def whitelisted_content_type?(content_type)
        Array(content_type_whitelist).any? do |item|
          item = Regexp.quote(item) if item.class != Regexp
          content_type =~ /#{item}/
        end
      end
  end
end