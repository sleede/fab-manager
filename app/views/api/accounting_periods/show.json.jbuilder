# frozen_string_literal: true

json.extract! @accounting_period, :id, :start_at, :end_at, :closed_at, :closed_by, :created_at
