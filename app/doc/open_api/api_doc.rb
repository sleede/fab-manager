# app/concerns/controllers/api_doc.rb
#
# Controller extension with common API documentation shortcuts
#

module OpenAPI::ApiDoc
  # Apipie doesn't allow to append anything to esisting
  #  description. It raises an error on double definition.
  #
  def append_desc(desc = "")
    _apipie_dsl_data[:description] << desc << "\n"
  end

  # Converts passed +code+ to the markdown
  #  by prepending 4 spaces to each line
  #
  # @param code [String]
  # @return [String]
  #
  def to_markdown_code(code)
    code.split("\n").map do |line|
      (" " * 4) + line
    end.join("\n")
  end

  # Includes passed list of json schemas
  #  to method description
  #
  # @example
  #   include_response_schema 'users.json', '_user.json'
  #
  # @param schemas [Array<String>]
  #
  def include_response_schema(*schemas)
    root = Rails.root.join('app/doc/responses')
    _apipie_dsl_data[:description] = _apipie_dsl_data[:description].strip_heredoc
    append_desc("## Response schema")

    schemas.each do |relative_path|
      append_desc MarkdownJsonSchema.read(relative_path)
    end
  end

  # Exports all documentation from provided class
  #
  # @example
  #   class ProfilesController < ApplicationController
  #     extend Controllers::ApiDoc
  #     expose_doc
  #     # exports all docs from ProfilesDoc class
  #     # that must be inherired from ApplicationDoc
  #   end
  #
  # @see ApplicationDoc
  #
  def expose_doc(doc_name = "#{controller_path}_doc")
    doc_klass = doc_name.classify.constantize
    doc_klass.apply(self)
  end
end
