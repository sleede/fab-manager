json.machines @machines do |machine|
  json.partial! 'open_api/v1/machines/machine', machine: machine
  json.extract! machine, :description, :spec
  json.hours_remaining @hours_remaining[machine.id]
end
