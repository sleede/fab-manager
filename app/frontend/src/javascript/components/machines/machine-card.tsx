import React, { ReactNode, useState } from 'react';
import { Machine } from '../../models/machine';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import { ReserveButton } from './reserve-button';
import { User } from '../../models/user';

interface MachineCardProps {
  user?: User,
  machine: Machine,
  onShowMachine: (machine: Machine) => void,
  onReserveMachine: (machine: Machine) => void,
  onLoginRequested: () => Promise<User>,
  onEnrollRequested: (trainingId: number) => void,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  canProposePacks: boolean,
}

/**
 * This component is a box showing the picture of the given machine and two buttons: one to start the reservation process
 * and another to redirect the user to the machine description page.
 */
const MachineCardComponent: React.FC<MachineCardProps> = ({ user, machine, onShowMachine, onReserveMachine, onError, onSuccess, onLoginRequested, onEnrollRequested, canProposePacks }) => {
  const { t } = useTranslation('public');

  // shall we display a loader to prevent double-clicking, while the machine details are loading?
  const [loading, setLoading] = useState<boolean>(false);

  /**
   * Callback triggered when the user clicks on the 'reserve' button and has passed all the verifications
   */
  const handleReserveMachine = (): void => {
    onReserveMachine(machine);
  };
  /**
   * Callback triggered when the user clicks on the 'view' button
   */
  const handleShowMachine = (): void => {
    onShowMachine(machine);
  };

  const machinePicture = (): ReactNode => {
    if (!machine.machine_image) {
      return <div className="machine-picture no-picture" />;
    }

    return (
      <div className="machine-picture" style={{ backgroundImage: `url(${machine.machine_image})` }} onClick={handleShowMachine} />
    );
  };

  return (
    <div className={`machine-card ${loading ? 'loading' : ''} ${machine.disabled ? 'disabled' : ''}`}>
      {machinePicture()}
      <div className="machine-name">
        {machine.name}
      </div>
      <div className="machine-actions">
        {!machine.disabled && <ReserveButton currentUser={user}
          machineId={machine.id}
          onLoadingStart={() => setLoading(true)}
          onLoadingEnd={() => setLoading(false)}
          onError={onError}
          onSuccess={onSuccess}
          onReserveMachine={handleReserveMachine}
          onLoginRequested={onLoginRequested}
          onEnrollRequested={onEnrollRequested}
          canProposePacks={canProposePacks}
          className="reserve-button">
          <i className="fas fa-bookmark" />
          {t('app.public.machine_card.book')}
        </ReserveButton>}
        <span>
          <button onClick={handleShowMachine} className="show-button">
            <i className="fas fa-eye" />
            {t('app.public.machine_card.consult')}
          </button>
        </span>
      </div>
    </div>
  );
};

export const MachineCard: React.FC<MachineCardProps> = ({ user, machine, onShowMachine, onReserveMachine, onError, onSuccess, onLoginRequested, onEnrollRequested, canProposePacks }) => {
  return (
    <Loader>
      <MachineCardComponent user={user} machine={machine} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} onError={onError} onSuccess={onSuccess} onLoginRequested={onLoginRequested} onEnrollRequested={onEnrollRequested} canProposePacks={canProposePacks} />
    </Loader>
  );
};
