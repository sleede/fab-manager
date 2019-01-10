# frozen_string_literal: true

# Validates the current invoice is not generated within a closed accounting period
class ClosedPeriodValidator < ActiveModel::Validator
  def validate(record)
    date = if record.is_a?(Avoir)
             record.avoir_date
           else
             DateTime.now
           end


    AccountingPeriod.all.each do |period|
      record.errors[:date] << I18n.t('errors.messages.in_closed_period') if date >= period.start_at && date <= period.end_at
    end
  end
end
