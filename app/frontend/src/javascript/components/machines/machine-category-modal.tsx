import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from '../base/fab-modal';
import { MachineCategory } from '../../models/machine-category';
import { Machine } from '../../models/machine';
import MachineCategoryAPI from '../../api/machine-category';
import { MachineCategoryForm } from './machine-category-form';
import MachineAPI from '../../api/machine';

interface MachineCategoryModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  machineCategory?: MachineCategory,
}

/**
 * Modal dialog to create/edit a machine category
 */
export const MachineCategoryModal: React.FC<MachineCategoryModalProps> = ({ isOpen, toggleModal, onSuccess, onError, machineCategory }) => {
  const { t } = useTranslation('admin');
  // all machines, to assign to the category
  const [machines, setMachines] = useState<Array<Machine>>([]);

  // retrieve the full list of machines on component mount
  useEffect(() => {
    if (!isOpen) return;

    MachineAPI.index({ category: [machineCategory?.id, 'none'] })
      .then(setMachines)
      .catch(onError);
  }, [isOpen]);

  /**
   * Save the current machine category to the API
   */
  const handleSaveMachineCategory = async (data: MachineCategory): Promise<void> => {
    try {
      if (machineCategory?.id) {
        await MachineCategoryAPI.update(data);
        onSuccess(t('app.admin.machine_category_modal.successfully_updated'));
      } else {
        await MachineCategoryAPI.create(data);
        onSuccess(t('app.admin.machine_category_modal.successfully_created'));
      }
    } catch (e) {
      if (machineCategory?.id) {
        onError(t('app.admin.machine_category_modal.unable_to_update') + e);
      } else {
        onError(t('app.admin.machine_category_modal.unable_to_create') + e);
      }
    }
  };

  return (
    <FabModal title={t(`app.admin.machine_category_modal.${machineCategory?.id ? 'edit' : 'new'}_machine_category`)}
      width={ModalSize.large}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}>
      <MachineCategoryForm machineCategory={machineCategory} machines={machines} saveMachineCategory={handleSaveMachineCategory}/>
    </FabModal>
  );
};
