import { useEffect, useState } from 'react';
import * as React from 'react';
import { Machine, MachineListFilter } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineAPI from '../../api/machine';
import MachineCategoryAPI from '../../api/machine-category';
import { MachineCategory } from '../../models/machine-category';
import { MachineCard } from './machine-card';
import { MachinesFilters } from './machines-filters';
import { User } from '../../models/user';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { EditorialBlock } from '../base/editorial-block';
import { CalendarBlank } from 'phosphor-react';

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
  const { t } = useTranslation('public');
  // shown machines
  const [machines, setMachines] = useState<Array<Machine>>(null);
  // we keep the full list of machines, for filtering
  const [allMachines, setAllMachines] = useState<Array<Machine>>(null);
  // shown machine categories
  const [machineCategories, setMachineCategories] = useState<Array<MachineCategory>>([]);
  // machine list filter
  const [filter, setFilter] = useState<MachineListFilter>({
    status: true,
    category: null
  });

  // retrieve the full list of machines on component mount
  useEffect(() => {
    MachineAPI.index()
      .then(data => setAllMachines(data))
      .catch(e => onError(e));
    MachineCategoryAPI.index()
      .then(data => setMachineCategories(data))
      .catch(e => onError(e));
  }, []);

  // filter the machines shown when the full list was retrieved
  useEffect(() => {
    handleFilter();
  }, [allMachines]);

  // filter the machines shown when the filter was changed
  useEffect(() => {
    handleFilter();
  }, [filter]);

  /**
   * Callback triggered when the user changes the filter.
   * filter the machines shown when the filter was changed.
   */
  const handleFilter = (): void => {
    let machinesFiltered = [];
    if (allMachines) {
      if (filter.status === null) {
        machinesFiltered = allMachines;
      } else {
        // enabled machines may have the m.disabled property null (for never disabled machines)
        // or false (for re-enabled machines)
        machinesFiltered = allMachines.filter(m => !!m.disabled === !filter.status);
      }
      if (filter.category !== null) {
        machinesFiltered = machinesFiltered.filter(m => m.machine_category_id === filter.category);
      }
    }
    setMachines(machinesFiltered);
  };

  /**
   * Callback triggered when the user changes the filter.
   * @param type, status, category
   * @param value, status and category value
   */
  const handleFilterChangedBy = (type: string, value: number | boolean | void) => {
    setFilter({
      ...filter,
      [type]: value
    });
  };

  return (
    <div className="machines-list">
      {/*  TODO: Condition to display editorial block */}
      {false &&
        <EditorialBlock />
      }
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
