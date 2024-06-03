import { ReactNode, useState } from 'react';
import * as React from 'react';
import { Machine } from '../../models/machine';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import { ReserveButton } from './reserve-button';
import { User } from '../../models/user';
import { FabBadge } from '../base/fab-badge';

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
const MachineCard: React.FC<MachineCardProps> = ({ user, machine, onShowMachine, onReserveMachine, onError, onSuccess, onLoginRequested, onEnrollRequested, canProposePacks }) => {
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

  /**
   * Return the machine's picture or a placeholder
   */
  const machinePicture = (): ReactNode => {
    if (!machine.machine_image_attributes?.attachment_url) {
      return <div className="machine-picture no-picture" />;
    }
    console.log(machine.machine_image_attributes.attachment_url);

    return (
      <div className="machine-picture" style={{ backgroundImage: `url("${machine.machine_image_attributes.attachment_url}"), url('/default-image.png')` }} onClick={handleShowMachine} />
    );
  };

  return (
    <div className={`machine-card ${loading ? 'loading' : ''} ${machine.disabled ? 'disabled' : ''} ${!machine.reservable ? 'unreservable' : ''}`}>
      {machinePicture()}
      {machine.space && user && user.role === 'admin' && <FabBadge icon='pin-map' iconWidth='3rem' /> }
      <div className="machine-name">
        {machine.name}
      </div>
      <div className="machine-actions">
        {!machine.disabled && machine.reservable && <ReserveButton currentUser={user}
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

const MachineCardWrapper: React.FC<MachineCardProps> = (props) => {
  return (
    <Loader>
      <MachineCard {...props} />
    </Loader>
  );
};

export { MachineCardWrapper as MachineCard };
