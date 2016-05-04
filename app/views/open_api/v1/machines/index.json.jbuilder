json.machines @machines do |machine|
  json.partial! 'open_api/v1/machines/machine', machine: machine
  json.extract! machine, :description, :spec
end
