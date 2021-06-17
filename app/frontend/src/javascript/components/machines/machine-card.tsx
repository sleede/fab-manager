import React, { ReactNode } from 'react';
import { Machine } from '../../models/machine';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';

interface MachineCardProps {
  machine: Machine,
  onShowMachine: (machine: Machine) => void,
  onReserveMachine: (machine: Machine) => void,
}

/**
 * This component is a box showing the picture of the given machine and two buttons: one to start the reservation process
 * and another to redirect the user to the machine description page.
 */
const MachineCardComponent: React.FC<MachineCardProps> = ({ machine, onShowMachine, onReserveMachine }) => {
  const { t } = useTranslation('public');

  /**
   * Callback triggered when the user clicks on the 'reserve' button.
   * We handle the training verification process here, before redirecting the user to the reservation calendar.
   */
  const handleReserveMachine = (): void => {
    onReserveMachine(machine);
  }

  /**
   * Callback triggered when the user clicks on the 'view' button
   */
  const handleShowMachine = (): void => {
    onShowMachine(machine);
  }

  const machinePicture = (): ReactNode => {
    if (!machine.machine_image) {
      return (
        <div className="machine-picture">
          <img src="data:image/png;base64,"
               data-src="holder.js/100%x100%/text:&#xf03e;/font:'Font Awesome 5 Free'/icon"
               className="img-responsive"
               alt={machine.name} />
        </div>
      );
    }

    return (
      <div className="machine-picture" style={{ backgroundImage: `url(${machine.machine_image})` }} onClick={handleShowMachine} />
    )
  }

  return (
    <div className="machine-card">
      {machinePicture()}
      <div className="machine-name">
        {machine.name}
      </div>
      <div className="machine-actions">
        {!machine.disabled && <button onClick={handleReserveMachine} className="reserve-button">
          <i className="fas fa-bookmark" />
          {t('app.public.machine_card.book')}
        </button>}
        <button onClick={handleShowMachine} className={`show-button ${machine.disabled ? 'single-button': ''}`}>
          <i className="fas fa-eye" />
          {t('app.public.machine_card.consult')}
        </button>
      </div>
    </div>
  );
}


export const MachineCard: React.FC<MachineCardProps> = ({ machine, onShowMachine, onReserveMachine }) => {
  return (
    <Loader>
      <MachineCardComponent machine={machine} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} />
    </Loader>
  );
}
