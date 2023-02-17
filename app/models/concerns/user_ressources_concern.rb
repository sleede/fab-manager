# frozen_string_literal: true

# Add resources-related functionalities to the user model (eg. Reservation, Subscription, Project, etc.)
module UserRessourcesConcern
  extend ActiveSupport::Concern

  included do
    def training_machine?(machine)
      return true if admin? || manager?

      trainings.map(&:machines).flatten.uniq.include?(machine)
    end

    def packs?(item)
      return true if admin?

      PrepaidPackService.user_packs(self, item).count.positive?
    end

    def next_training_reservation_by_machine(machine)
      reservations.where(reservable_type: 'Training', reservable_id: machine.trainings.map(&:id))
                  .includes(:slots)
                  .where('slots.start_at>= ?', Time.current)
                  .order('slots.start_at': :asc)
                  .references(:slots)
                  .limit(1)
                  .first
    end

    def subscribed_plan
      return nil if subscription.nil? || subscription.expired_at < Time.current

      subscription.plan
    end

    def subscription
      subscriptions.order(:created_at).last
    end

    def all_projects
      my_projects.to_a.concat projects
    end
  end
end
