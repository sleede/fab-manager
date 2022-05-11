import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { PendingTrainingModal } from './pending-training-modal';
import { RequiredTrainingModal } from './required-training-modal';
import { Loader } from '../base/loader';
import { ProposePacksModal } from '../prepaid-packs/propose-packs-modal';
import MachineAPI from '../../api/machine';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import SettingAPI from '../../api/setting';
import { SettingName } from '../../models/setting';

declare const Application: IApplication;

interface ReserveButtonProps {
  currentUser?: User,
  machineId: number,
  onLoadingStart?: () => void,
  onLoadingEnd?: () => void,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  onReserveMachine: (machine: Machine) => void,
  onLoginRequested: () => Promise<User>,
  onEnrollRequested: (trainingId: number) => void,
  className?: string,
  canProposePacks: boolean,
}

/**
 * Button component that makes the training verification before redirecting the user to the reservation calendar
 */
const ReserveButtonComponent: React.FC<ReserveButtonProps> = ({ currentUser, machineId, onLoginRequested, onLoadingStart, onLoadingEnd, onError, onSuccess, onReserveMachine, onEnrollRequested, className, children, canProposePacks }) => {
  const { t } = useTranslation('shared');

  const [machine, setMachine] = useState<Machine>(null);
  const [user, setUser] = useState<User>(currentUser);
  const [pendingTraining, setPendingTraining] = useState<boolean>(false);
  const [trainingRequired, setTrainingRequired] = useState<boolean>(false);
  const [proposePacks, setProposePacks] = useState<boolean>(false);
  const [isPackOnlyForSubscription, setIsPackOnlyForSubscription] = useState<boolean>(true);

  // handle login from an external process
  useEffect(() => setUser(currentUser), [currentUser]);
  // check the trainings after we retrieved the machine data
  useEffect(() => checkTraining(), [machine]);
  useEffect(() => {
    SettingAPI.get(SettingName.PackOnlyForSubscription)
      .then(data => setIsPackOnlyForSubscription(data.value === 'true'))
      .catch(error => onError(error));
  }, []);

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
   * Open/closes the modal dialog inviting the user to buy a prepaid-pack
   */
  const toggleProposePacksModal = (): void => {
    setProposePacks(!proposePacks);
  };

  /**
   * Callback triggered when the user has successfully bought a pre-paid pack.
   * Display the success message and redirect him to the booking page.
   */
  const handlePackBought = (message: string, machine: Machine): void => {
    onSuccess(message);
    onReserveMachine(machine);
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
    // a prior training, move forward to the prepaid-packs verification.
    // Moreover, if there's no enabled associated trainings, also move to the next step.
    if (machine.current_user_is_trained || machine.trainings.length === 0 ||
        machine.trainings.map(t => t.disabled).reduce((acc, val) => acc && val, true)) {
      return checkPrepaidPack();
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

  /**
   * Once the training condition has been verified, we check if there are prepaid-packs to propose to the customer.
   */
  const checkPrepaidPack = (): void => {
    // if the customer has already bought a pack or if there's no active packs for this machine,
    // or customer has not any subscription if admin active pack only for subscription option
    // let the customer reserve
    if (machine.current_user_has_packs || !machine.has_prepaid_packs_for_current_user || (isPackOnlyForSubscription && !user.subscribed_plan) || !canProposePacks) {
      return onReserveMachine(machine);
    }

    // otherwise, we show a dialog modal to propose the customer to buy an available pack
    setProposePacks(true);
  };

  return (
    <span>
      <button onClick={handleClick} className={className || ''}>
        {children && children}
        {!children && <span>{t('app.shared.reserve_button.book_this_machine')}</span>}
      </button>
      <PendingTrainingModal isOpen={pendingTraining}
        toggleModal={togglePendingTrainingModal}
        nextReservation={machine?.current_user_next_training_reservation?.slots_attributes[0]?.start_at} />
      <RequiredTrainingModal isOpen={trainingRequired}
        toggleModal={toggleRequiredTrainingModal}
        user={user}
        machine={machine}
        onEnrollRequested={onEnrollRequested} />
      {machine && user && <ProposePacksModal isOpen={proposePacks}
        toggleModal={toggleProposePacksModal}
        item={machine}
        itemType="Machine"
        onError={onError}
        customer={user}
        onDecline={onReserveMachine}
        operator={user}
        onSuccess={handlePackBought} />}
    </span>

  );
};

export const ReserveButton: React.FC<ReserveButtonProps> = ({ currentUser, machineId, onLoginRequested, onLoadingStart, onLoadingEnd, onError, onSuccess, onReserveMachine, onEnrollRequested, className, children, canProposePacks }) => {
  return (
    <Loader>
      <ReserveButtonComponent currentUser={currentUser} machineId={machineId} onError={onError} onSuccess={onSuccess} onLoadingStart={onLoadingStart} onLoadingEnd={onLoadingEnd} onReserveMachine={onReserveMachine} onLoginRequested={onLoginRequested} onEnrollRequested={onEnrollRequested} className={className} canProposePacks={canProposePacks}>
        {children}
      </ReserveButtonComponent>
    </Loader>
  );
};

Application.Components.component('reserveButton', react2angular(ReserveButton, ['currentUser', 'machineId', 'onLoadingStart', 'onLoadingEnd', 'onError', 'onSuccess', 'onReserveMachine', 'onLoginRequested', 'onEnrollRequested', 'className', 'canProposePacks']));
