import React, { useEffect, useState } from 'react';
import { PendingTrainingModal } from './pending-training-modal';
import MachineAPI from '../../api/machine';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';
import { RequiredTrainingModal } from './required-training-modal';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';

declare var Application: IApplication;

interface ReserveButtonProps {
  currentUser?: User,
  machineId: number,
  onLoadingStart?: () => void,
  onLoadingEnd?: () => void,
  onError: (message: string) => void,
  onReserveMachine: (machine: Machine) => void,
  onLoginRequested: () => Promise<User>,
  onEnrollRequested: (trainingId: number) => void,
  className?: string
}

/**
 * Button component that makes the training verification before redirecting the user to the reservation calendar
 */
const ReserveButtonComponent: React.FC<ReserveButtonProps> = ({ currentUser, machineId, onLoginRequested, onLoadingStart, onLoadingEnd, onError, onReserveMachine, onEnrollRequested, className, children }) => {
  const { t } = useTranslation('shared');

  const [machine, setMachine] = useState<Machine>(null);
  const [user, setUser] = useState<User>(currentUser);
  const [pendingTraining, setPendingTraining] = useState<boolean>(false);
  const [trainingRequired, setTrainingRequired] = useState<boolean>(false);

  // handle login from an external process
  useEffect(() => setUser(currentUser), [currentUser]);
  // check the trainings after we retrieved the machine data
  useEffect(() => checkTraining(), [machine]);

  /**
   * Callback triggered when the user clicks on the 'reserve' button.
   */
  const handleClick = (): void => {
    getMachine();
  };

  /**
   * We load the full machine data, including data on the current user status for this machine.
   * Then we check if the user has passed the training for it (if it's needed)
   */
  const getMachine = (): void => {
    if (onLoadingStart) onLoadingStart();

    MachineAPI.get(machineId)
      .then(data => {
        setMachine(data);
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
   * Open/closes the alert modal informing the user about his pending training
   */
  const toggleRequiredTrainingModal = (): void => {
    setTrainingRequired(!trainingRequired);
  };

  /**
   * Check that the current user has passed the required training before allowing him to book
   */
  const checkTraining = (): void => {
    // do nothing if the machine is still not loaded
    if (!machine) return;

    // if there's no user currently logged, trigger the logging process
    if (!user) {
      onLoginRequested()
        .then(() => getMachine())
        .catch(error => onError(error));
      return;
    }

    // if the currently logged user has completed the training for this machine, or this machine does not require
    // a prior training, just let him reserve.
    // Moreover, if all associated trainings are disabled, let the user reserve too.
    if (machine.current_user_is_trained || machine.trainings.length === 0 ||
        machine.trainings.map(t => t.disabled).reduce((acc, val) => acc && val, true)) {
      return onReserveMachine(machine);
    }

    // if the currently logged user booked a training for this machine, tell him that he must wait
    // for an admin to validate the training before he can book the reservation
    if (machine.current_user_next_training_reservation) {
      return setPendingTraining(true);
    }

    // if the currently logged user doesn't have booked the required training, tell him to register
    // for a training session first
    setTrainingRequired(true);
  };

  return (
    <span>
      <button onClick={handleClick} className={className ? className : ''}>
        {children && children}
        {!children && <span>{t('app.shared.reserve_button.book_this_machine')}</span>}
      </button>
      <PendingTrainingModal isOpen={pendingTraining}
                            toggleModal={togglePendingTrainingModal}
                            nextReservation={machine?.current_user_next_training_reservation?.slots_attributes[0]?.start_at}  />
      <RequiredTrainingModal isOpen={trainingRequired}
                             toggleModal={toggleRequiredTrainingModal}
                             user={user}
                             machine={machine}
                             onEnrollRequested={onEnrollRequested} />
    </span>

  );
}

export const ReserveButton: React.FC<ReserveButtonProps> = ({ currentUser, machineId, onLoginRequested, onLoadingStart, onLoadingEnd, onError, onReserveMachine, onEnrollRequested, className, children }) => {
  return (
    <Loader>
      <ReserveButtonComponent currentUser={currentUser} machineId={machineId} onError={onError} onLoadingStart={onLoadingStart} onLoadingEnd={onLoadingEnd} onReserveMachine={onReserveMachine} onLoginRequested={onLoginRequested} onEnrollRequested={onEnrollRequested} className={className}>
        {children}
      </ReserveButtonComponent>
    </Loader>
  );
}

Application.Components.component('reserveButton', react2angular(ReserveButton, ['currentUser', 'machineId', 'onLoadingStart', 'onLoadingEnd', 'onError', 'onReserveMachine', 'onLoginRequested', 'onEnrollRequested', 'className']));
