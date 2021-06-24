import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { Loader } from '../base/loader';
import { PrepaidPack } from '../../models/prepaid-pack';
import PrepaidPackAPI from '../../api/prepaid-pack';


interface DeletePackProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  pack: PrepaidPack,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog to ask the user for confirmation about the deletion of the provided pack.
 */
const DeletePackComponent: React.FC<DeletePackProps> = ({ onSuccess, onError, pack }) => {
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
   * Call the API to trigger the deletion of the temporary set plan-category
   */
  const onDeleteConfirmed = (): void => {
    PrepaidPackAPI.destroy(pack.id).then(() => {
      onSuccess(t('app.admin.delete_pack.pack_deleted'));
    }).catch((error) => {
      onError(t('app.admin.delete_pack.unable_to_delete') + error);
    });
    toggleDeletionModal();
  };

  return (
    <div className="delete-pack">
      <FabButton type='button' className="remove-pack-button" icon={<i className="fa fa-trash" />} onClick={toggleDeletionModal} />
      <FabModal title={t('app.admin.delete_pack.delete_pack')}
                isOpen={deletionModal}
                toggleModal={toggleDeletionModal}
                closeButton={true}
                confirmButton={t('app.admin.delete_pack.confirm_delete')}
                onConfirm={onDeleteConfirmed}>
        <span>{t('app.admin.delete_pack.delete_confirmation')}</span>
      </FabModal>
    </div>
  )
};


export const DeletePack: React.FC<DeletePackProps> = ({ onSuccess, onError, pack }) => {
  return (
    <Loader>
      <DeletePackComponent onSuccess={onSuccess} onError={onError} pack={pack} />
    </Loader>
  );
}
