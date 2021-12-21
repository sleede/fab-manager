import React, { useState } from 'react';
import { FabModal } from '../base/fab-modal';
import { TimeslotForm } from './timeslot-form';
import { Price } from '../../models/price';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';

interface CreateTimeslotProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog handing the process of creating a new time slot
 */
export const CreateTimeslot: React.FC<CreateTimeslotProps> = ({ onSuccess, onError, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  const [isOpen, setIsOpen] = useState<boolean>(false);

  /**
   * Open/closes the "new pack" modal dialog
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Callback triggered when the user has validated the creation of the new time slot
   */
  const handleSubmit = (timeslot: Price): void => {
    // set the already-known attributes of the new pack
    const newTimeslot = Object.assign<Price, Price>({} as Price, timeslot);
    newTimeslot.group_id = groupId;
    newTimeslot.priceable_id = priceableId;
    newTimeslot.priceable_type = priceableType;

    // create it on the API
    console.log('newTimeslot :', newTimeslot);
    // PrepaidPackAPI.create(newPack)
    //  .then(() => {
    //    onSuccess(t('app.admin.create_timeslot.timeslot_successfully_created'));
    //    toggleModal();
    //  })
    //  .catch(error => onError(error));
  };

  return (
    <div className="create-pack">
      <button className="add-pack-button" onClick={toggleModal}><i className="fas fa-plus"/></button>
      <FabModal isOpen={isOpen}
        toggleModal={toggleModal}
        title={t('app.admin.create_timeslot.new_timeslot')}
        className="new-pack-modal"
        closeButton
        confirmButton={t('app.admin.create_timeslot.create_timeslot')}
        onConfirmSendFormId="new-pack">
        <FabAlert level="info">
          {t('app.admin.create_timeslot.new_timeslot_info', { TYPE: priceableType })}
        </FabAlert>
        <TimeslotForm formId="new-pack" onSubmit={handleSubmit} />
      </FabModal>
    </div>
  );
};
