import React, { useState } from 'react';
import { FabModal } from '../base/fab-modal';
import { PackForm } from './pack-form';
import { PrepaidPack } from '../../models/prepaid-pack';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';

interface EditPackProps {
  pack: PrepaidPack,
  onSuccess: (message: string) => void,
  onError: (message: string) => void
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog handing the process of creating a new PrepaidPack
 */
export const EditPack: React.FC<EditPackProps> = ({ pack, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [packData, setPackData] = useState<PrepaidPack>(null);

  /**
   * Open/closes the "edit pack" modal dialog
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  }

  /**
   * When the user clicks on the edition button, query the full data of the current pack from the API, then open te edition modal
   */
  const handleRequestEdit = (): void => {
    PrepaidPackAPI.get(pack.id)
      .then(data => {
        setPackData(data);
        toggleModal();
      })
      .catch(error => onError(error));
  }

  /**
   * Callback triggered when the user has validated the changes of the PrepaidPack
   */
  const handleUpdate = (pack: PrepaidPack): void => {
    PrepaidPackAPI.update(pack)
      .then(() => {
        onSuccess(t('app.admin.edit_pack.pack_successfully_updated'));
        toggleModal();
      })
      .catch(error => onError(error));
  }

  return (
    <div className="edit-pack">
      <FabButton type='button' className="edit-pack-button" icon={<i className="fas fa-edit" />} onClick={handleRequestEdit} />
      <FabModal isOpen={isOpen}
                toggleModal={toggleModal}
                title={t('app.admin.edit_pack.edit_pack')}
                className="edit-pack-modal"
                closeButton
                confirmButton={t('app.admin.edit_pack.confirm_changes')}
                onConfirmSendFormId="edit-pack">
        {packData && <PackForm formId="edit-pack" onSubmit={handleUpdate} pack={packData} />}
      </FabModal>
    </div>
  );
}
