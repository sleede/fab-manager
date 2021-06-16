import React, { useEffect, useState } from 'react';
import { Machine } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineAPI from '../../api/machine';
import { MachineCard } from './machine-card';

declare var Application: IApplication;

interface MachinesListProps {
  onError: (message: string) => void,
  onShowMachine: (machine: Machine) => void,
  onReserveMachine: (machine: Machine) => void,
}

/**
 * This component shows a list of all machines and allows filtering on that list.
 */
const MachinesList: React.FC<MachinesListProps> = ({ onError, onShowMachine, onReserveMachine }) => {
  const [machines, setMachines] = useState<Array<Machine>>(null);

  useEffect(() => {
    MachineAPI.index()
      .then(data => setMachines(data))
      .catch(e => onError(e));
  }, []);

  return (
    <div className="machines-list">
      {machines && machines.map(machine => {
        return <MachineCard machine={machine} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} />
      })}
    </div>
  );
}


const MachinesListWrapper: React.FC<MachinesListProps> = ({ onError, onShowMachine, onReserveMachine }) => {
  return (
    <Loader>
      <MachinesList onError={onError} onShowMachine={onShowMachine} onReserveMachine={onReserveMachine} />
    </Loader>
  );
}

Application.Components.component('machinesList', react2angular(MachinesListWrapper, ['onError', 'onShowMachine', 'onReserveMachine']));
