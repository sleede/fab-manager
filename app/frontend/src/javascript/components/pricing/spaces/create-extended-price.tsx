import React, { useState } from 'react';
import { FabModal } from '../../base/fab-modal';
import { ExtendedPriceForm } from './extended-price-form';
import { Price } from '../../../models/price';
import PriceAPI from '../../../api/price';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../../base/fab-alert';

interface CreateExtendedPriceProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog handing the process of creating a new extended price
 */
export const CreateExtendedPrice: React.FC<CreateExtendedPriceProps> = ({ onSuccess, onError, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  const [isOpen, setIsOpen] = useState<boolean>(false);

  /**
   * Open/closes the "new pack" modal dialog
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Callback triggered when the user has validated the creation of the new extended price
   */
  const handleSubmit = (extendedPrice: Price): void => {
    // set the already-known attributes of the new pack
    const newExtendedPrice = Object.assign<Price, Price>({} as Price, extendedPrice);
    newExtendedPrice.group_id = groupId;
    newExtendedPrice.priceable_id = priceableId;
    newExtendedPrice.priceable_type = priceableType;

    // create it on the API
    PriceAPI.create(newExtendedPrice)
      .then(() => {
        onSuccess(t('app.admin.create_extendedPrice.extendedPrice_successfully_created'));
        toggleModal();
      })
      .catch(error => onError(error));
  };

  return (
    <div className="create-pack">
      <button className="add-pack-button" onClick={toggleModal}><i className="fas fa-plus"/></button>
      <FabModal isOpen={isOpen}
        toggleModal={toggleModal}
        title={t('app.admin.create_extendedPrice.new_extendedPrice')}
        className="new-pack-modal"
        closeButton
        confirmButton={t('app.admin.create_extendedPrice.create_extendedPrice')}
        onConfirmSendFormId="new-pack">
        <FabAlert level="info">
          {t('app.admin.create_extendedPrice.new_extendedPrice_info', { TYPE: priceableType })}
        </FabAlert>
        <ExtendedPriceForm formId="new-pack" onSubmit={handleSubmit} />
      </FabModal>
    </div>
  );
};
