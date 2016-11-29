class Setting < ActiveRecord::Base
  validates :name, inclusion:
                    { in: %w(about_title
                             about_body
                             about_contacts
                             twitter_name
                             home_blogpost
                             machine_explications_alert
                             training_explications_alert
                             training_information_message
                             subscription_explications_alert
                             invoice_logo
                             invoice_reference
                             invoice_code-active
                             invoice_code-value
                             invoice_order-nb
                             invoice_VAT-active
                             invoice_VAT-rate
                             invoice_text
                             invoice_legals
                             booking_window_start
                             booking_window_end
                             booking_slot_duration
                             booking_move_enable
                             booking_move_delay
                             booking_cancel_enable
                             booking_cancel_delay
                             main_color
                             secondary_color
                             fablab_name
                             name_genre
                             reminder_enable
                             reminder_delay
                             event_explications_alert )
                    }

  after_update :update_stylesheet if :value_changed?

  def update_stylesheet
    if %w(main_color secondary_color).include? self.name
      Stylesheet.first.rebuild!
    end
  end


end
