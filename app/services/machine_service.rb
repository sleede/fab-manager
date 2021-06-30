# frozen_string_literal: true

# Provides methods for Machines
class MachineService
  def self.list(filters)
    sort_by = Setting.get('machines_sort_by') || 'default'
    machines = if sort_by == 'default'
                 Machine.includes(:machine_image, :plans)
               else
                 Machine.includes(:machine_image, :plans).order(sort_by)
               end
    if filters[:disabled].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      machines = machines.where(disabled: state)
    end

    machines
  end
end
