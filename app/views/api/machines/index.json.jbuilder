# frozen_string_literal: true

json.array!(@machines) do |machine|
  json.partial! 'api/machines/machine', machine: machine
end
