# frozen_string_literal: true

class PublicReservationIcalController < ApplicationController
  skip_before_action :verify_authenticity_token

  def type_ics
    cal = ReservationCalendarService.new(params).call
    # send_data cal.to_ical, type: 'text/calendar', disposition: 'inline', filename: "#{params[:reservable_type]}_reservations.ics"
    render plain: cal.to_ical
  end
end
