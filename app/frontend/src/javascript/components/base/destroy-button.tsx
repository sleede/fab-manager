import { ReactNode, useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabButton } from './fab-button';
import { FabModal } from './fab-modal';
import { Trash } from 'phosphor-react';

interface DestroyButtonProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  itemId: number,
  itemType: string,
  apiDestroy: (itemId: number) => Promise<void>,
  confirmationMessage?: string|ReactNode,
  className?: string,
  iconSize?: number
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog to ask the user for confirmation about the deletion of the provided item.
 */
export const DestroyButton: React.FC<DestroyButtonProps> = ({ onSuccess, onError, itemId, itemType, apiDestroy, confirmationMessage, className, iconSize = 24 }) => {
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
      onSuccess(t('app.admin.destroy_button.deleted', { TYPE: itemType }));
    }).catch((error) => {
      onError(t('app.admin.destroy_button.unable_to_delete', { TYPE: itemType }) + error);
    });
    toggleDeletionModal();
  };

  return (
    <div className='destroy-button'>
      <FabButton type='button' className={className} onClick={toggleDeletionModal}>
        <Trash size={iconSize} weight="fill" />
      </FabButton>
      <FabModal title={t('app.admin.destroy_button.delete_item', { TYPE: itemType })}
        isOpen={deletionModal}
        toggleModal={toggleDeletionModal}
        closeButton={true}
        confirmButton={t('app.admin.destroy_button.confirm_delete')}
        onConfirm={onDeleteConfirmed}>
        <span>{confirmationMessage || t('app.admin.destroy_button.delete_confirmation', { TYPE: itemType })}</span>
      </FabModal>
    </div>
  );
};
