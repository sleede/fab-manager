# frozen_string_literal: true

# ChildService
class ChildService
  def self.create(child)
    if child.save
      NotificationCenter.call type: 'notify_admin_child_created',
                              receiver: User.admins_and_managers,
                              attached_object: child

      if all_supporting_documents_present?(child)
        NotificationCenter.call type: 'notify_admin_user_child_supporting_document_files_created',
                                receiver: User.admins_and_managers,
                                attached_object: child
      end

      return true
    end
    false
  end

  def self.update(child, child_params)
    has_new_attachment = new_attachment_uploaded?(child_params)

    if child.update(child_params)
      if has_new_attachment && all_supporting_documents_present?(child)
        NotificationCenter.call type: 'notify_admin_user_child_supporting_document_files_updated',
                                receiver: User.admins_and_managers,
                                attached_object: child
      end

      return true
    end
    false
  end

  def self.validate(child, is_valid)
    is_updated = child.update(validated_at: is_valid ? Time.current : nil)
    if is_updated
      if is_valid
        NotificationCenter.call type: 'notify_user_child_is_validated',
                                receiver: child.user,
                                attached_object: child
      else
        NotificationCenter.call type: 'notify_user_child_is_invalidated',
                                receiver: child.user,
                                attached_object: child
      end
    end
    is_updated
  end

  class << self
    private

    def new_attachment_uploaded?(child_params)
      files_attrs = child_params[:supporting_document_files_attributes] ||
                    child_params['supporting_document_files_attributes']
      return false if files_attrs.blank?

      attrs_list = normalize_supporting_documents_attributes(files_attrs)
      attrs_list.any? do |attrs|
        next false if attrs.blank?

        destroy_flag = attrs[:_destroy] || attrs['_destroy']
        next false if ActiveModel::Type::Boolean.new.cast(destroy_flag)

        (attrs[:attachment] || attrs['attachment']).present?
      end
    end

    def normalize_supporting_documents_attributes(files_attrs)
      case files_attrs
      when Array
        files_attrs
      when Hash, ActionController::Parameters
        if files_attrs.key?(:id) || files_attrs.key?('id')
          [files_attrs]
        else
          files_attrs.values
        end
      else
        Array(files_attrs)
      end
    end

    def all_supporting_documents_present?(child)
      SupportingDocumentType.where(document_type: 'Child').all? do |sdt|
        file = sdt.supporting_document_files.find_by(supportable: child)
        file&.attachment_identifier.present?
      end
    end
  end
end
