import { PencilSimple, Trash } from 'phosphor-react';
import * as React from 'react';
import { ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabButton } from './fab-button';
import { FabModal } from './fab-modal';

type EditDestroyButtonsCommon = {
  onError: (message: string) => void,
  onEdit: () => void,
  itemId: number,
  destroy: (itemId: number) => Promise<void>,
  className?: string,
  iconSize?: number,
  showEditButton?: boolean,
}

type DeleteSuccess =
  { onDeleteSuccess: (message: string) => void, deleteSuccessMessage: string } |
  { onDeleteSuccess?: never, deleteSuccessMessage?: never }

type DestroyMessages =
  ({ showDestroyConfirmation?: true } &
    ({ itemType: string, confirmationTitle?: string, confirmationMessage?: string|ReactNode } |
     { itemType?: never, confirmationTitle: string, confirmationMessage: string|ReactNode })) |
  { showDestroyConfirmation: false, itemType?: never, confirmationTitle?: never, confirmationMessage?: never };

type EditDestroyButtonsProps = EditDestroyButtonsCommon & DeleteSuccess & DestroyMessages;

/**
 * This component shows a group of two buttons.
 * Destroy : shows a modal dialog to ask the user for confirmation about the deletion of the provided item.
 * Edit : triggers the provided function.
 */
export const EditDestroyButtons: React.FC<EditDestroyButtonsProps> = ({ onDeleteSuccess, onError, onEdit, itemId, itemType, destroy, confirmationTitle, confirmationMessage, deleteSuccessMessage, className, iconSize = 20, showEditButton = true, showDestroyConfirmation = true }) => {
  const { t } = useTranslation('admin');

  const [deletionModal, setDeletionModal] = useState<boolean>(false);

  /**
   * Opens/closes the deletion modal
   */
  const toggleDeletionModal = (): void => {
    setDeletionModal(!deletionModal);
  };

  /**
   * Triggered when the user clicks on the 'destroy' button
   */
  const handleDestroyRequest = (): void => {
    if (showDestroyConfirmation) {
      toggleDeletionModal();
    } else {
      onDeleteConfirmed();
    }
  };

  /**
   * The deletion has been confirmed by the user.
   * Call the API to trigger the deletion of the given item
   */
  const onDeleteConfirmed = (): void => {
    destroy(itemId).then(() => {
      typeof onDeleteSuccess === 'function' && onDeleteSuccess(deleteSuccessMessage || t('app.admin.edit_destroy_buttons.deleted'));
    }).catch((error) => {
      onError(t('app.admin.edit_destroy_buttons.unable_to_delete') + error);
    });
    setDeletionModal(false);
  };

  return (
    <>
      <div className={`edit-destroy-buttons ${className || ''}`}>
        {showEditButton && <FabButton className='edit-btn' onClick={onEdit}>
          <PencilSimple size={iconSize} weight="fill" />
        </FabButton>}
        <FabButton type='button' className='delete-btn' onClick={handleDestroyRequest}>
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
