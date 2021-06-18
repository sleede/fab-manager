import React, { BaseSyntheticEvent, useState } from 'react';
import { PendingTrainingModal } from './pending-training-modal';
import MachineAPI from '../../api/machine';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';

interface ReserveButtonProps {
  currentUser?: User,
  machineId: number,
  onLoadingStart?: () => void,
  onLoadingEnd?: () => void,
  onError: (message: string) => void,
  onReserveMachine: (machineId: number) => void,
  onLoginRequested: () => Promise<User>,
  className?: string
}

/**
 * Button component that makes the training verification before redirecting the user to the reservation calendar
 */
export const ReserveButton: React.FC<ReserveButtonProps> = ({ currentUser, machineId, onLoginRequested, onLoadingStart, onLoadingEnd, onError, onReserveMachine, className, children }) => {

  const [machine, setMachine] = useState<Machine>(null);
  const [pendingTraining, setPendingTraining] = useState<boolean>(false);

  /**
   * Callback triggered when the user clicks on the 'reserve' button.
   */
  const handleClick = (event: BaseSyntheticEvent): void => {
    event.preventDefault();
    getMachine(currentUser);
  };

  /**
   * We load the full machine data, including data on the current user status for this machine.
   * Then we check if the user has passed the training for it (if it's needed)
   */
  const getMachine = (user: User): void => {
    if (onLoadingStart) onLoadingStart();

    MachineAPI.get(machineId)
      .then(data => {
        setMachine(data);
        checkTraining(data, user);
        if (onLoadingEnd) onLoadingEnd();
      })
      .catch(error => {
        onError(error);
        if (onLoadingEnd) onLoadingEnd();
      });
  };

  /**
   * Open/closes the alert modal informing the user about his pending training
   */
  const togglePendingTrainingModal = (): void => {
    setPendingTraining(!pendingTraining);
  };

  /**
   * Check that the current user has passed the required training before allowing him to book
   */
  const checkTraining = (machine: Machine, user?: User): void => {
    // if there's no user currently logged, trigger the logging process
    if (!user) {
      onLoginRequested()
        .then(user => getMachine(user))
        .catch(error => onError(error));
      return;
    }

    // if the currently logged user has completed the training for this machine, or this machine does not require
    // a prior training, just let him booking
    if (machine.current_user_is_trained || machine.trainings.length === 0) {
      return onReserveMachine(machineId);
    }

    // if there's an authenticated user, and he booked a training for this machine, tell him that he must wait
    // for an admin to validate the training before he can book the reservation
    if (machine.current_user_next_training_reservation) {
      return setPendingTraining(true);
    }
  };

  return (
    <span>
      <button onClick={handleClick} className={className}>
        {children}
      </button>
      <PendingTrainingModal isOpen={pendingTraining}
                            toggleModal={togglePendingTrainingModal}
                            nextReservation={machine?.current_user_next_training_reservation?.slots_attributes[0]?.start_at}  />
    </span>

  );
}
