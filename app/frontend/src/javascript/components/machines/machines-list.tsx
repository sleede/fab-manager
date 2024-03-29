import { useEffect, useState } from 'react';
import * as React from 'react';
import { Machine, MachineIndexFilter } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineAPI from '../../api/machine';
import MachineCategoryAPI from '../../api/machine-category';
import { MachineCategory } from '../../models/machine-category';
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
export const MachinesList: React.FC<MachinesListProps> = ({ onError, onSuccess, onShowMachine, onReserveMachine, onLoginRequested, onEnrollRequested, user, canProposePacks }) => {
  // shown machines
  const [machines, setMachines] = useState<Array<Machine>>(null);
  // shown machine categories
  const [machineCategories, setMachineCategories] = useState<Array<MachineCategory>>([]);
  // machine list filter
  const [filters, setFilters] = useState<MachineIndexFilter>({
    disabled: false,
    category: null
  });

  // retrieve the full list of machines on component mount
  useEffect(() => {
    MachineAPI.index(filters)
      .then(data => setMachines(data))
      .catch(e => onError(e));
    MachineCategoryAPI.index()
      .then(data => setMachineCategories(data))
      .catch(e => onError(e));
  }, []);

  // refetch the machines when the filters change
  useEffect(() => {
    MachineAPI.index(filters)
      .then(data => setMachines(data))
      .catch(e => onError(e));
  }, [filters]);

  /**
   * Callback triggered when the user changes the filter.
   * @param type, status, category
   * @param value, status and category value
   */
  const handleFilterChangedBy = (type: string, value: number | boolean | void) => {
    setFilters({
      ...filters,
      [type]: value
    });
  };

  return (
    <div className="machines-list">
      <MachinesFilters onFilterChangedBy={handleFilterChangedBy} machineCategories={machineCategories}/>
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

const MachinesListWrapper: React.FC<MachinesListProps> = (props) => {
  return (
    <Loader>
      <MachinesList {...props} />
    </Loader>
  );
};

Application.Components.component('machinesList', react2angular(MachinesListWrapper, ['user', 'onError', 'onSuccess', 'onShowMachine', 'onReserveMachine', 'onLoginRequested', 'onEnrollRequested', 'canProposePacks']));
