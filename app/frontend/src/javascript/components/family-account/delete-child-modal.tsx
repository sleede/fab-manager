import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { Child } from '../../models/child';

interface DeleteChildModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  child: Child,
  onDelete: (child: Child) => void,
}

/**
 * Modal dialog to remove a requested child
 */
export const DeleteChildModal: React.FC<DeleteChildModalProps> = ({ isOpen, toggleModal, onDelete, child }) => {
  const { t } = useTranslation('public');

  /**
   * Callback triggered when the child confirms the deletion
   */
  const handleDeleteChild = () => {
    onDelete(child);
  };

  return (
    <FabModal title={t('app.public.delete_child_modal.confirmation_required')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={t('app.public.delete_child_modal.confirm')}
      onConfirm={handleDeleteChild}
      className="delete-child-modal">
      <p>{t('app.public.delete_child_modal.confirm_delete_child')}</p>
    </FabModal>
  );
};
