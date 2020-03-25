# frozen_string_literal: true

# MachineImage is the main picture for a Machine
class MachineImage < Asset
  mount_uploader :attachment, MachineImageUploader
end
