# frozen_string_literal: true

json.title notification.notification_type
json.description t('.import_over', CATEGORY: t(".#{notification.attached_object.category}")) +
                 link_to(t('.view_results'), "#!/admin/members/import/#{notification.attached_object.id}/results")
json.url notification_url(notification, format: :json)
