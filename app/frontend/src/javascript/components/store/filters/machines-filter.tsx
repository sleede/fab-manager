import React, { useEffect, useState } from 'react';
import { FabButton } from '../../base/fab-button';
import { AccordionItem } from '../../base/accordion-item';
import { useTranslation } from 'react-i18next';
import { Machine } from '../../../models/machine';
import MachineAPI from '../../../api/machine';
import _ from 'lodash';

interface MachinesFilterProps {
  allMachines?: Array<Machine>,
  onError: (message: string) => void,
  onApplyFilters: (categories: Array<Machine>) => void,
  currentFilters: Array<Machine>,
  openDefault?: boolean,
  instantUpdate?: boolean
}

/**
 * Component to filter the products list by associated machine
 */
export const MachinesFilter: React.FC<MachinesFilterProps> = ({ allMachines, onError, onApplyFilters, currentFilters, openDefault = false, instantUpdate = false }) => {
  const { t } = useTranslation('admin');

  const [machines, setMachines] = useState<Machine[]>(allMachines);
  const [openedAccordion, setOpenedAccordion] = useState<boolean>(openDefault);
  const [selectedMachines, setSelectedMachines] = useState<Machine[]>(currentFilters || []);

  useEffect(() => {
    if (_.isEmpty(allMachines)) {
      MachineAPI.index({ disabled: false }).then(data => {
        setMachines(data);
      }).catch(onError);
    }
  }, []);

  useEffect(() => {
    if (currentFilters && !_.isEqual(currentFilters, selectedMachines)) {
      setSelectedMachines(currentFilters);
    }
  }, [currentFilters]);

  /**
   * Open/close the accordion item
   */
  const handleAccordion = (id, state: boolean) => {
    setOpenedAccordion(state);
  };

  /**
   * Callback triggered when a machine filter is seleced or unselected.
   */
  const handleSelectMachine = (currentMachine: Machine, checked: boolean) => {
    const list = [...selectedMachines];
    checked
      ? list.push(currentMachine)
      : list.splice(list.indexOf(currentMachine), 1);

    setSelectedMachines(list);
    if (instantUpdate) {
      onApplyFilters(list);
    }
  };

  return (
    <>
      <AccordionItem id={1}
                     isOpen={openedAccordion}
                     onChange={handleAccordion}
                     label={t('app.admin.store.machines_filter.filter_machines')}>
        <div className='content'>
          <div className="group u-scrollbar">
            {machines.map(m => (
              <label key={m.id}>
                <input type="checkbox" checked={selectedMachines.includes(m)} onChange={(event) => handleSelectMachine(m, event.target.checked)} />
                <p>{m.name}</p>
              </label>
            ))}
          </div>
          <FabButton onClick={() => onApplyFilters(selectedMachines)} className="is-info">{t('app.admin.store.machines_filter.filter_apply')}</FabButton>
        </div>
      </AccordionItem>
    </>
  );
};
