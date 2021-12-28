import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../../base/fab-button';
import { FabModal } from '../../base/fab-modal';
import { Price } from '../../../models/price';
import PriceAPI from '../../../api/price';

interface DeleteExtendedPriceProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  price: Price,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog to ask the user for confirmation about the deletion of the provided extended price.
 */
export const DeleteExtendedPrice: React.FC<DeleteExtendedPriceProps> = ({ onSuccess, onError, price }) => {
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
   * Call the API to trigger the deletion of the temporary set extended price
   */
  const onDeleteConfirmed = (): void => {
    PriceAPI.destroy(price.id).then(() => {
      onSuccess(t('app.admin.delete_extended_price.extended_price_deleted'));
    }).catch((error) => {
      onError(t('app.admin.delete_extended_price.unable_to_delete') + error);
    });
    toggleDeletionModal();
  };

  return (
    <div className="delete-extended-price">
      <FabButton type='button' className="remove-price-button" icon={<i className="fa fa-trash" />} onClick={toggleDeletionModal} />
      <FabModal title={t('app.admin.delete_extended_price.delete_extended_price')}
        isOpen={deletionModal}
        toggleModal={toggleDeletionModal}
        closeButton={true}
        confirmButton={t('app.admin.delete_extended_price.confirm_delete')}
        onConfirm={onDeleteConfirmed}>
        <span>{t('app.admin.delete_extended_price.delete_confirmation')}</span>
      </FabModal>
    </div>
  );
};
