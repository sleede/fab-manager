import { PencilSimple, Trash } from 'phosphor-react';
import * as React from 'react';
import { ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabButton } from './fab-button';
import { FabModal } from './fab-modal';

interface EditDestroyButtonsProps {
  onDeleteSuccess: (message: string) => void,
  onError: (message: string) => void,
  onEdit: () => void,
  itemId: number,
  itemType: string,
  apiDestroy: (itemId: number) => Promise<void>,
  confirmationTitle?: string,
  confirmationMessage?: string|ReactNode,
  className?: string,
  iconSize?: number,
  showEditButton?: boolean,
}

/**
 * This component shows a group of two buttons.
 * Destroy : shows a modal dialog to ask the user for confirmation about the deletion of the provided item.
 * Edit : triggers the provided function.
 */
export const EditDestroyButtons: React.FC<EditDestroyButtonsProps> = ({ onDeleteSuccess, onError, onEdit, itemId, itemType, apiDestroy, confirmationTitle, confirmationMessage, className, iconSize = 20, showEditButton = true }) => {
  const { t } = useTranslation('admin');

  const [deletionModal, setDeletionModal] = useState<boolean>(false);

  /**
   * Opens/closes the deletion modal
   */
  const toggleDeletionModal = (): void => {
    setDeletionModal(!deletionModal);
  };

  /**
   * The deletion has been confirmed by the user.
   * Call the API to trigger the deletion of the given item
   */
  const onDeleteConfirmed = (): void => {
    apiDestroy(itemId).then(() => {
      onDeleteSuccess(t('app.admin.edit_destroy_buttons.deleted', { TYPE: itemType }));
    }).catch((error) => {
      onError(t('app.admin.edit_destroy_buttons.unable_to_delete', { TYPE: itemType }) + error);
    });
    toggleDeletionModal();
  };

  return (
    <>
      <div className={`edit-destroy-buttons ${className || ''}`}>
        {showEditButton && <FabButton className='edit-btn' onClick={onEdit}>
          <PencilSimple size={iconSize} weight="fill" />
        </FabButton>}
        <FabButton type='button' className='delete-btn' onClick={toggleDeletionModal}>
          <Trash size={iconSize} weight="fill" />
        </FabButton>
      </div>
      <FabModal title={confirmationTitle || t('app.admin.edit_destroy_buttons.delete_item', { TYPE: itemType })}
        isOpen={deletionModal}
        toggleModal={toggleDeletionModal}
        closeButton={true}
        confirmButton={t('app.admin.edit_destroy_buttons.confirm_delete')}
        onConfirm={onDeleteConfirmed}>
        <span>{confirmationMessage || t('app.admin.edit_destroy_buttons.delete_confirmation', { TYPE: itemType })}</span>
      </FabModal>
    </>
  );
};
