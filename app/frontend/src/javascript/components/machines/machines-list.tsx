import React, { useEffect, useState } from 'react';
import { Machine } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineAPI from '../../api/machine';
import { MachineCard } from './machine-card';
import { MachinesFilters } from './machines-filters';
import { User } from '../../models/user';

declare const Application: IApplication;

interface MachinesListProps {
  user?: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  onShowMachine: (machine: Machine) => void,
  onReserveMachine: (machine: Machine) => void,
  onLoginRequested: () => Promise<User>,
  onEnrollRequested: (trainingId: number) => void,
  canProposePacks: boolean,
}

/**
 * This component shows a list of all machines and allows filtering on that list.
 */
const MachinesList: React.FC<MachinesListProps> = ({ onError, onSuccess, onShowMachine, onReserveMachine, onLoginRequested, onEnrollRequested, user, canProposePacks }) => {
  // shown machines
  const [machines, setMachines] = useState<Array<Machine>>(null);
  // we keep the full list of machines, for filtering
  const [allMachines, setAllMachines] = useState<Array<Machine>>(null);

  // retrieve the full list of machines on component mount
  useEffect(() => {
    MachineAPI.index()
      .then(data => setAllMachines(data))
      .catch(e => onError(e));
  }, []);

  // filter the machines shown when the full list was retrieved
  useEffect(() => {
    handleFilterByStatus(true);
  }, [allMachines]);

  /**
   * Callback triggered when the user changes the status filter.
   * Set the 'machines' state to a filtered list, depending on the provided parameter.
   * @param status, true = enabled machines, false = disabled machines, null = all machines
   */
  const handleFilterByStatus = (status: boolean): void => {
    if (!allMachines) return;
    if (status === null) return setMachines(allMachines);

    // enabled machines may have the m.disabled property null (for never disabled machines)
    // or false (for re-enabled machines)
    setMachines(allMachines.filter(m => !!m.disabled === !status));
  };

  return (
    <div className="machines-list">
      <MachinesFilters onStatusSelected={handleFilterByStatus} />
      <div className="all-machines">
        {machines && machines.map(machine => {
          return <MachineCard key={machine.id}
            user={user}
            machine={machine}
            onShowMachine={onShowMachine}
            onReserveMachine={onReserveMachine}
            onError={onError}
            onSuccess={onSuccess}
            onLoginRequested={onLoginRequested}
            onEnrollRequested={onEnrollRequested}
            canProposePacks={canProposePacks}/>;
        })}
      </div>
    </div>
  );
};

const MachinesListWrapper: React.FC<MachinesListProps> = ({ user, onError, onSuccess, onShowMachine, onReserveMachine, onLoginRequested, onEnrollRequested, canProposePacks }) => {
  return (
    <Loader>
      <MachinesList user={user} onError={onError} onSuccess={onSuccess} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} onLoginRequested={onLoginRequested} onEnrollRequested={onEnrollRequested} canProposePacks={canProposePacks}/>
    </Loader>
  );
};

Application.Components.component('machinesList', react2angular(MachinesListWrapper, ['user', 'onError', 'onSuccess', 'onShowMachine', 'onReserveMachine', 'onLoginRequested', 'onEnrollRequested', 'canProposePacks']));
