import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';
import { UserPack } from '../../models/user-pack';
import UserPackAPI from '../../api/user-pack';
import SettingAPI from '../../api/setting';
import { SettingName } from '../../models/setting';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { ProposePacksModal } from './propose-packs-modal';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';

declare var Application: IApplication;

type PackableItem = Machine;

interface PacksSummaryProps {
  item: PackableItem,
  itemType: 'Machine',
  customer?: User,
  operator: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

const PacksSummaryComponent: React.FC<PacksSummaryProps> = ({ item, itemType, customer, operator, onError, onSuccess }) => {
  const { t } = useTranslation('logged');

  const [userPacks, setUserPacks] = useState<Array<UserPack>>(null);
  const [threshold, setThreshold] = useState<number>(null);
  const [packsModal, setPacksModal] = useState<boolean>(false);

  useEffect(() => {
    SettingAPI.get(SettingName.RenewPackThreshold)
      .then(data => setThreshold(parseFloat(data.value)))
      .catch(error => onError(error));
  }, []);

  useEffect(() => {
    if (_.isEmpty(customer)) return;

    UserPackAPI.index({ user_id: customer.id, priceable_type: itemType, priceable_id: item.id })
      .then(data => setUserPacks(data))
      .catch(error => onError(error));
  }, [item, itemType, customer]);

  /**
   * Total of minutes used by the customer
   */
  const totalUsed = (): number => {
    if (!userPacks) return 0;

    return userPacks.map(up => up.minutes_used).reduce((acc, curr) => acc + curr, 0);
  }

  /**
   * Total of minutes available is the packs bought by the customer
   */
  const totalAvailable = (): number => {
    if (!userPacks) return 0;

    return userPacks.map(up => up.prepaid_pack.minutes).reduce((acc, curr) => acc + curr, 0);
  }

  /**
   * Total prepaid hours remaining for the current customer
   */
  const totalHours = (): number => {
    return (totalAvailable() - totalUsed()) / 60;
  }

  /**
   * Do we need to display the "buy new pack" button?
   */
  const shouldDisplayButton = (): boolean => {
    if (threshold < 1) {
      return totalAvailable() - totalUsed() <= totalAvailable() * threshold;
    }

    return totalAvailable() - totalUsed() <= threshold * 60;
  }

  /**
   * Open/closes the prepaid-pack buying modal
   */
  const togglePacksModal = (): void => {
    setPacksModal(!packsModal);
  }

  /**
   * Callback triggered when the customer has successfully bought a prepaid-pack
   */
  const handlePackBoughtSuccess = (message: string): void => {
    onSuccess(message);
    togglePacksModal();
    UserPackAPI.index({ user_id: customer.id, priceable_type: itemType, priceable_id: item.id })
      .then(data => setUserPacks(data))
      .catch(error => onError(error));
  }

  // prevent component rendering if no customer selected
  if (_.isEmpty(customer)) return <div />;

  return (
    <div className="packs-summary">
      <h3>{t('app.logged.packs_summary.prepaid_hours')}</h3>
      <div className="content">
        <span className="remaining-hours">{t('app.logged.packs_summary.remaining_HOURS', { HOURS: totalHours(), ITEM: itemType })}</span>
        {shouldDisplayButton() && <div className="button-wrapper">
          <FabButton className="buy-button" onClick={togglePacksModal} icon={<i className="fa fa-shopping-cart"/>}>
            {t('app.logged.packs_summary.buy_a_new_pack')}
          </FabButton>
          <ProposePacksModal isOpen={packsModal}
                             toggleModal={togglePacksModal}
                             item={item}
                             itemType={itemType}
                             customer={customer}
                             operator={operator}
                             onError={onError}
                             onDecline={togglePacksModal}
                             onSuccess={handlePackBoughtSuccess} />
        </div>}
      </div>
    </div>
  );
}

export const PacksSummary: React.FC<PacksSummaryProps> = ({ item, itemType, customer, operator, onError, onSuccess }) => {
  return (
    <Loader>
      <PacksSummaryComponent item={item} itemType={itemType} customer={customer} operator={operator} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
}

Application.Components.component('packsSummary', react2angular(PacksSummary, ['item', 'itemType', 'customer', 'operator', 'onError', 'onSuccess']));
