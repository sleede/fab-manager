json.title notification.notification_type
json.description t('.export')+' '+
                 t(".#{notification.attached_object.category}_#{notification.attached_object.export_type}")+' '+
                 t('.is_over')+' '+
                 link_to( t('.download_here'), "api/exports/#{notification.attached_object.id}/download" )+'.'
json.url notification_url(notification, format: :json)