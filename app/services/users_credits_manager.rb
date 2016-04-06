class UsersCreditsManager
  attr_reader :manager

  def initialize(reservation)
    if reservation.reservable_type == "Training"
      @manager = Training.new(reservation)
    elsif reservation.reservable_type == "Machine"
      @manager = Machine.new(reservation)
    end
  end

  class Machine < Manager
    def will_use_credits?
    end

    def credited_hours_number
    end

    def update
      super
    end

    private
      def _will_use_credits?
      end
  end

  class Training < Manager
    def will_use_credits?
      _will_use_credits?[0]
    end

    def update
      super
      will_use_credits, training_credit = _will_use_credits?
      if will_use_credits
        user.credits << training_credit # we create a new UsersCredit object
      end
    end

    private
      def _will_use_credits?
        # if there is a training_credit defined for this plan and this training
        if training_credit = plan.training_credits.find_by(creditable_id: reservation.reservable_id)
          # if user has not used all the plan credits
          if user.training_credits.count < plan.training_credit_nb
            return true, training_credit
          end
        end
        return false, nil
      end
  end

  private
    class Manager
      attr_reader :reservation

      def initialize(reservation)
        @reservation = reservation
        @already_updated = false
      end

      def plan
        user.subscribed_plan
      end

      def user
        reservation.user
      end

      def update
        if @already_updated
          raise AlreadyUpdated, "update credit is not idempotent ! do not try to update twice."
        else
          @already_updated = true
        end
      end
    end

    class AlreadyUpdated < StandardError
    end
end
