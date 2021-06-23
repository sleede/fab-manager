import React from 'react';
import { FabModal } from '../base/fab-modal';
import { PackForm } from './pack-form';
import { PrepaidPack } from '../../models/prepaid-pack';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';

interface NewPackModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component is a modal dialog handing the process of creating a new PrepaidPack
 */
export const NewPackModal: React.FC<NewPackModalProps> = ({ isOpen, toggleModal, onSuccess, onError, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  /**
   * Callback triggered when the user has validated the creation of the new PrepaidPack
   */
  const handleSubmit = (pack: PrepaidPack): void => {
    // set the already-known attributes of the new pack
    const newPack = Object.assign<PrepaidPack, PrepaidPack>({} as PrepaidPack, pack);
    newPack.group_id = groupId;
    newPack.priceable_id = priceableId;
    newPack.priceable_type = priceableType;

    // create it on the API
    PrepaidPackAPI.create(newPack)
      .then(() => {
        onSuccess(t('app.admin.new_pack_modal.pack_successfully_created'));
        toggleModal();
      })
      .catch(error => onError(error));
  }

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              title={t('app.admin.new_pack_modal.new_pack')}
              className="new-pack-modal"
              closeButton
              confirmButton={t('app.admin.new_pack_modal.create_pack')}
              onConfirmSendFormId="new-pack">
      <FabAlert level="info">
        {t('app.admin.new_pack_modal.new_pack_info', { TYPE: priceableType })}
      </FabAlert>
      <PackForm formId="new-pack" onSubmit={handleSubmit} />
    </FabModal>
  );
}
