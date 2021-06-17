import React, { useState } from 'react';
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

  const [pendingTraining, setPendingTraining] = useState<boolean>(false);

  /**
   * Callback triggered when the user clicks on the 'reserve' button.
   * We load the full machine data, then we check if the user has passed the training for it (if it's needed)
   */
  const handleClick = (user?: User): void => {
    if (onLoadingStart) onLoadingStart();

    MachineAPI.get(machineId)
      .then(data => {
        checkTraining(data, user);
        if (onLoadingEnd) onLoadingEnd();
      })
      .catch(error => {
        onError(error);
        if (onLoadingEnd) onLoadingEnd();
      });
  }

  /**
   * Check that the current user has passed the required training before allowing him to book
   */
  const checkTraining = (machine: Machine, user?: User): void => {
    // if there's no user currently logged, trigger the logging process
    if (!user) {
      onLoginRequested()
        .then(user => handleClick(user))
        .catch(error => onError(error));
      return;
    }

    // if the currently logged user has completed the training for this machine, or this machine does not require
    // a prior training, just let him booking
    if (machine.current_user_is_trained || machine.trainings.length === 0) {
      return onReserveMachine(machineId);
    }

    // if a user is authenticated and have booked a training for this machine, tell him that he must wait
    // for an admin to validate the training before he can book the reservation
    if (machine.current_user_next_training_reservation) {
      return setPendingTraining(true);
    }
  }

  return (
    <span>
      <button onClick={() => handleClick(currentUser)} className={className}>
        {children}
      </button>
    </span>
  );
}
