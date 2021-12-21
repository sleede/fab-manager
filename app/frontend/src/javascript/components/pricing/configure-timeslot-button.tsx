import React, { ReactNode, useState } from 'react';
import { Price } from '../../models/price';
import { useTranslation } from 'react-i18next';
import { FabPopover } from '../base/fab-popover';
import { CreateTimeslot } from './create-timeslot';
import PriceAPI from '../../api/price';
import FormatLib from '../../lib/format';

interface ConfigureTimeslotButtonProps {
  prices: Array<Price>,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  groupId: number,
  priceableId: number,
  priceableType: string,
}

/**
 * This component is a button that shows the list of timeslots.
 * It also triggers modal dialogs to configure (add/delete/edit/remove) timeslots.
 */
export const ConfigureTimeslotButton: React.FC<ConfigureTimeslotButtonProps> = ({ prices, onError, onSuccess, groupId, priceableId, priceableType }) => {
  const { t } = useTranslation('admin');

  const [timeslots, setTimeslots] = useState<Array<Price>>(prices);
  const [showList, setShowList] = useState<boolean>(false);

  /**
   * Open/closes the popover listing the existing packs
   */
  const toggleShowList = (): void => {
    setShowList(!showList);
  };

  /**
   * Callback triggered when the timeslot was successfully created/deleted/updated.
   * We refresh the list of timeslots.
   */
  const handleSuccess = (message: string) => {
    onSuccess(message);
    PriceAPI.index({ group_id: groupId, priceable_id: priceableId, priceable_type: priceableType })
      .then(data => setTimeslots(data))
      .catch(error => onError(error));
  };

  /**
   * Render the button used to trigger the "new pack" modal
   */
  const renderAddButton = (): ReactNode => {
    return <CreateTimeslot onSuccess={handleSuccess}
      onError={onError}
      groupId={groupId}
      priceableId={priceableId}
      priceableType={priceableType} />;
  };

  return (
    <div className="configure-packs-button">
      <button className="packs-button" onClick={toggleShowList}>
        <i className="fas fa-box" />
      </button>
      {showList && <FabPopover title={t('app.admin.configure_timeslots_button.timeslots')} headerButton={renderAddButton()} className="fab-popover__right">
        <ul>
          {timeslots?.map(timeslot =>
            <li key={timeslot.id}>
              {timeslot.duration} {t('app.admin.calendar.minutes')} - {FormatLib.price(timeslot.amount)}
              <span className="pack-actions">
              </span>
            </li>)}
        </ul>
        {timeslots?.length === 0 && <span>{t('app.admin.configure_timeslots_button.no_timeslots')}</span>}
      </FabPopover>}
    </div>
  );
};
