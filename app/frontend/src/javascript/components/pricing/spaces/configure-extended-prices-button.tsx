import { ReactNode, useState } from 'react';
import * as React from 'react';
import { Price } from '../../../models/price';
import { useTranslation } from 'react-i18next';
import { FabPopover } from '../../base/fab-popover';
import { CreateExtendedPrice } from './create-extended-price';
import PriceAPI from '../../../api/price';
import FormatLib from '../../../lib/format';
import { EditExtendedPrice } from './edit-extended-price';
import { DeleteExtendedPrice } from './delete-extended-price';

interface ConfigureExtendedPricesButtonProps {
  prices: Array<Price>,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component is a button that shows the list of extendedPrices.
 * It also triggers modal dialogs to configure (add/edit/remove) extendedPrices.
 */
export const ConfigureExtendedPricesButton: React.FC<ConfigureExtendedPricesButtonProps> = ({ prices, onError, onSuccess, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  const [extendedPrices, setExtendedPrices] = useState<Array<Price>>(prices);
  const [showList, setShowList] = useState<boolean>(false);

  /**
   * Return the number of hours, user-friendly formatted
   */
  const formatDuration = (minutes: number): string => {
    return t('app.admin.configure_extended_prices_button.extended_price_DURATION', { DURATION: minutes / 60 });
  };

  /**
   * Open/closes the popover listing the existing packs
   */
  const toggleShowList = (): void => {
    setShowList(!showList);
  };

  /**
   * Callback triggered when the extendedPrice was successfully created/deleted/updated.
   * We refresh the list of extendedPrices.
   */
  const handleSuccess = (message: string) => {
    onSuccess(message);
    PriceAPI.index({ group_id: groupId, priceable_id: priceableId, priceable_type: priceableType })
      .then(data => setExtendedPrices(data.filter(p => p.duration !== 60)))
      .catch(error => onError(error));
  };

  /**
   * Render the button used to trigger the "new extended price" modal
   */
  const renderAddButton = (): ReactNode => {
    return <CreateExtendedPrice onSuccess={handleSuccess}
      onError={onError}
      groupId={groupId}
      priceableId={priceableId}
      priceableType={priceableType} />;
  };

  return (
    <div className="configure-extended-prices-button">
      <button className="extended-prices-button" onClick={toggleShowList}>
        <i className="fas fa-stopwatch" />
      </button>
      {showList && <FabPopover title={t('app.admin.configure_extended_prices_button.extended_prices')} headerButton={renderAddButton()} position="right">
        <ul>
          {extendedPrices?.map(extendedPrice =>
            <li key={extendedPrice.id}>
              {formatDuration(extendedPrice.duration)} - {FormatLib.price(extendedPrice.amount)}
              <span className="extended-prices-actions">
                <EditExtendedPrice onSuccess={handleSuccess} onError={onError} price={extendedPrice} />
                <DeleteExtendedPrice onSuccess={handleSuccess} onError={onError} price={extendedPrice} />
              </span>
            </li>)}
        </ul>
        {extendedPrices?.length === 0 && <span>{t('app.admin.configure_extended_prices_button.no_extended_prices')}</span>}
      </FabPopover>}
    </div>
  );
};
