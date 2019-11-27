# frozen_string_literal: true

# API Controller for resources of type iCalendar
class API::ICalendarController < API::ApiController
  before_action :authenticate_user!, except: %i[index events]
  before_action :set_i_cal, only: [:destroy]
  respond_to :json

  def index
    @i_cals = ICalendar.all
  end

  def create
    authorize ICalendar
    @i_cal = ICalendar.new(i_calendar_params)
    if @i_cal.save
      render :show, status: :created, location: @i_cal
    else
      render json: @i_cal.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize ICalendar
    @i_cal.destroy
    head :no_content
  end

  def events
    require 'net/http'
    require 'uri'
    require 'icalendar'

    @events = []

    @i_cals = ICalendar.all.each do |i_cal|
      ics = Net::HTTP.get(URI.parse(i_cal.url))
      cals = Icalendar::Calendar.parse(ics)

      cals.first.events.each do |evt|
        @events.push(evt.merge!(color: i_cal.color))
      end
    end
  end

  private

  def set_i_cal
    @i_cal = ICalendar.find(params[:id])
  end

  def i_calendar_params
    params.require(:i_calendar).permit(:url, :color, :text_color, :text_hidden)
  end
end
