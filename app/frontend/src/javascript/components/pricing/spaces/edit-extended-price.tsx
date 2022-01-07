import React, { useState } from 'react';
import { FabModal } from '../../base/fab-modal';
import { ExtendedPriceForm } from './extended-price-form';
import { Price } from '../../../models/price';
import PriceAPI from '../../../api/price';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../../base/fab-button';

interface EditExtendedPriceProps {
  price: Price,
  onSuccess: (message: string) => void,
  onError: (message: string) => void
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog handing the process of creating a new extended price
 */
export const EditExtendedPrice: React.FC<EditExtendedPriceProps> = ({ price, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [extendedPriceData, setExtendedPriceData] = useState<Price>(price);

  /**
   * Open/closes the "edit extended price" modal dialog
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * When the user clicks on the edition button open te edition modal
   */
  const handleRequestEdit = (): void => {
    toggleModal();
  };

  /**
   * Callback triggered when the user has validated the changes of the extended price
   */
  const handleUpdate = (price: Price): void => {
    PriceAPI.update(price)
      .then(() => {
        onSuccess(t('app.admin.edit_extended_price.extended_price_successfully_updated'));
        setExtendedPriceData(price);
        toggleModal();
      })
      .catch(error => onError(error));
  };

  return (
    <div className="edit-extended-price">
      <FabButton type='button' className="edit-price-button" icon={<i className="fas fa-edit" />} onClick={handleRequestEdit} />
      <FabModal isOpen={isOpen}
        toggleModal={toggleModal}
        title={t('app.admin.edit_extended_price.edit_extended_price')}
        className="edit-pack-modal"
        closeButton
        confirmButton={t('app.admin.edit_extended_price.confirm_changes')}
        onConfirmSendFormId="edit-extended-price">
        {extendedPriceData && <ExtendedPriceForm formId="edit-extended-price" onSubmit={handleUpdate} price={extendedPriceData} />}
      </FabModal>
    </div>
  );
};
