# frozen_string_literal: true

# Provides methods for Machines
class MachineService
  class << self
    # @param filters [ActionController::Parameters]
    def list(filters)
      sort_by = Setting.get('machines_sort_by') || 'default'
      machines = if sort_by == 'default'
                   Machine.includes(:machine_image, :plans)
                 else
                   Machine.includes(:machine_image, :plans).order(sort_by)
                 end
      # do not include soft destroyed
      machines = machines.where(deleted_at: nil)

      machines = filter_by_disabled(machines, filters)
      filter_by_category(machines, filters)
    end

    private

    # @param machines [ActiveRecord::Relation<Machine>]
    # @param filters [ActionController::Parameters]
    def filter_by_disabled(machines, filters)
      return machines if filters[:disabled].blank?

      state = filters[:disabled] == 'false' ? [nil, false] : true
      machines.where(disabled: state)
    end

    # @param machines [ActiveRecord::Relation<Machine>]
    # @param filters [ActionController::Parameters]
    def filter_by_category(machines, filters)
      return machines if filters[:category].blank?

      machines.where(machine_category_id: filters[:category])
    end
  end
end
