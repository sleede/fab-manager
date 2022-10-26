# frozen_string_literal: true

json.title notification.notification_type
json.description t('.low_stock', PRODUCT: t(".#{notification.attached_object.name}")) +
                   link_to(t('.view_product'), "#!/admin/store/products/#{notification.attached_object.id}/edit")
