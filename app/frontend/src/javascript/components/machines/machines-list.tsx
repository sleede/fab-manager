import React, { useEffect, useState } from 'react';
import { Machine } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineAPI from '../../api/machine';
import { MachineCard } from './machine-card';
import { MachinesFilters } from './machines-filters';
import { User } from '../../models/user';

declare var Application: IApplication;

interface MachinesListProps {
  user?: User,
  onError: (message: string) => void,
  onShowMachine: (machine: Machine) => void,
  onReserveMachine: (machine: Machine) => void,
  onLoginRequested: () => Promise<User>,
}

/**
 * This component shows a list of all machines and allows filtering on that list.
 */
const MachinesList: React.FC<MachinesListProps> = ({ onError, onShowMachine, onReserveMachine, onLoginRequested, user }) => {
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
  }, [allMachines])

  /**
   * Callback triggered when the user changes the status filter.
   * Set the 'machines' state to a filtered list, depending on the provided parameter.
   */
  const handleFilterByStatus = (status: boolean): void => {
    if (!allMachines) return;
    if (status === null) return setMachines(allMachines);

    setMachines(allMachines.filter(m => m.disabled === !status));
  }

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
                              onLoginRequested={onLoginRequested} />
        })}
      </div>
    </div>
  );
}


const MachinesListWrapper: React.FC<MachinesListProps> = ({ user, onError, onShowMachine, onReserveMachine, onLoginRequested }) => {
  return (
    <Loader>
      <MachinesList user={user} onError={onError} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} onLoginRequested={onLoginRequested} />
    </Loader>
  );
}

Application.Components.component('machinesList', react2angular(MachinesListWrapper, ['user', 'onError', 'onShowMachine', 'onReserveMachine', 'onLoginRequested']));
