import React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import MachineCategoryAPI from '../../api/machine-category';

interface DeleteMachineCategoryModalProps {
  isOpen: boolean,
  machineCategoryId: number,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog to remove a requested machine category
 */
export const DeleteMachineCategoryModal: React.FC<DeleteMachineCategoryModalProps> = ({ isOpen, toggleModal, onSuccess, machineCategoryId, onError }) => {
  const { t } = useTranslation('admin');

  /**
   * The user has confirmed the deletion of the requested machine category
   */
  const handleDeleteMachineCategory = async (): Promise<void> => {
    try {
      await MachineCategoryAPI.destroy(machineCategoryId);
      onSuccess(t('app.admin.delete_machine_category_modal.deleted'));
    } catch (e) {
      onError(t('app.admin.delete_machine_category_modal.unable_to_delete') + e);
    }
  };

  return (
    <FabModal title={t('app.admin.delete_machine_category_modal.confirmation_required')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={t('app.admin.delete_machine_category_modal.confirm')}
      onConfirm={handleDeleteMachineCategory}
      className="delete-machine-category-modal">
      <p>{t('app.admin.delete_machine_category_modal.confirm_machine_category')}</p>
    </FabModal>
  );
};
