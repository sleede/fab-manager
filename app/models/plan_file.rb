# frozen_string_literal: true

# PlanFile is a file stored on the file system, associated with a Plan.
# It is known as an information sheet for a plan, in the user interface.
class PlanFile < Asset
  mount_uploader :attachment, PlanFileUploader
end
