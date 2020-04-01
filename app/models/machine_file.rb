# frozen_string_literal: true

# MachineFile is a file stored on the file system, associated with a Machine.
# It is known as an attachment for a space, in the user interface.
class MachineFile < Asset
  mount_uploader :attachment, MachineFileUploader
end
