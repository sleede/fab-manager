import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';
import { UserPack } from '../../models/user-pack';
import UserPackAPI from '../../api/user-pack';
import SettingAPI from '../../api/setting';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { ProposePacksModal } from './propose-packs-modal';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { PrepaidPack } from '../../models/prepaid-pack';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { FabAlert } from '../base/fab-alert';

declare const Application: IApplication;

type PackableItem = Machine;

interface PacksSummaryProps {
  item: PackableItem,
  itemType: 'Machine',
  customer?: User,
  operator: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  refresh?: Promise<void>
}

/**
 * Display a short summary of the prepaid-packs already bought by the provider customer, for the given item.
 * May also allows members to buy directly some new prepaid-packs.
 */
const PacksSummary: React.FC<PacksSummaryProps> = ({ item, itemType, customer, operator, onError, onSuccess, refresh }) => {
  const { t } = useTranslation('logged');

  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);
  const [userPacks, setUserPacks] = useState<Array<UserPack>>(null);
  const [threshold, setThreshold] = useState<number>(null);
  const [packsModal, setPacksModal] = useState<boolean>(false);
  const [isPackOnlyForSubscription, setIsPackOnlyForSubscription] = useState<boolean>(true);

  useEffect(() => {
    SettingAPI.get('renew_pack_threshold')
      .then(data => setThreshold(parseFloat(data.value)))
      .catch(error => onError(error));
    SettingAPI.get('pack_only_for_subscription')
      .then(data => setIsPackOnlyForSubscription(data.value === 'true'))
      .catch(error => onError(error));
  }, []);

  useEffect(() => {
    getUserPacksData();
  }, [customer, item, itemType]);

  useEffect(() => {
    if (refresh instanceof Promise) {
      refresh.then(getUserPacksData);
    }
  }, [refresh]);

  /**
   * Fetch the user packs data from the API
   */
  const getUserPacksData = (): void => {
    if (_.isEmpty(customer)) return;

    UserPackAPI.index({ user_id: customer.id, priceable_type: itemType, priceable_id: item.id })
      .then(data => setUserPacks(data))
      .catch(error => onError(error));
    PrepaidPackAPI.index({ priceable_id: item.id, priceable_type: itemType, group_id: customer.group_id, disabled: false })
      .then(data => setPacks(data))
      .catch(error => onError(error));
  };

  /**
   * Total of minutes used by the customer
   */
  const totalUsed = (): number => {
    if (!userPacks) return 0;

    return userPacks.map(up => up.minutes_used).reduce((acc, curr) => acc + curr, 0);
  };

  /**
   * Total of minutes available is the packs bought by the customer
   */
  const totalAvailable = (): number => {
    if (!userPacks) return 0;

    return userPacks.map(up => up.prepaid_pack.minutes).reduce((acc, curr) => acc + curr, 0);
  };

  /**
   * Total prepaid hours remaining for the current customer
   */
  const totalHours = (): number => {
    return (totalAvailable() - totalUsed()) / 60;
  };

  /**
   * Do we need to display the "buy new pack" button?
   */
  const shouldDisplayButton = (): boolean => {
    if (!packs?.length) return false;

    if (threshold < 1) {
      return totalAvailable() - totalUsed() <= totalAvailable() * threshold;
    }

    return totalAvailable() - totalUsed() <= threshold * 60;
  };

  /**
   * Open/closes the prepaid-pack buying modal
   */
  const togglePacksModal = (): void => {
    setPacksModal(!packsModal);
  };

  /**
   * Callback triggered when the customer has successfully bought a prepaid-pack
   */
  const handlePackBoughtSuccess = (message: string): void => {
    onSuccess(message);
    togglePacksModal();
    UserPackAPI.index({ user_id: customer.id, priceable_type: itemType, priceable_id: item.id })
      .then(data => setUserPacks(data))
      .catch(error => onError(error));
  };

  // prevent component rendering if no customer selected
  if (_.isEmpty(customer)) return <div />;
  // prevent component rendering if ths customer have no packs and there are no packs available
  if (totalHours() === 0 && packs?.length === 0) return <div/>;
  // render remaining hours and a warning if customer has not any subscription if admin active pack only for subscription option
  if (totalHours() > 0) {
    return (
      <div className="packs-summary">
        <h3>{t('app.logged.packs_summary.prepaid_hours')}</h3>
        <div className="content">
          <span className="remaining-hours">
            {t('app.logged.packs_summary.remaining_HOURS', { HOURS: totalHours(), ITEM: itemType })}
            {isPackOnlyForSubscription && !customer.subscribed_plan &&
              <FabAlert level="warning">
                {t('app.logged.packs_summary.unable_to_use_pack_for_subsription_is_expired')}
              </FabAlert>
            }
          </span>
        </div>
      </div>
    );
  }
  // prevent component rendering buy pack button if customer has not any subscription if admin active pack only for subscription option
  if (isPackOnlyForSubscription && !customer.subscribed_plan) return <div/>;

  return (
    <div className="packs-summary">
      <h3>{t('app.logged.packs_summary.prepaid_hours')}</h3>
      <div className="content">
        <span className="remaining-hours">
          {totalHours() === 0 && t('app.logged.packs_summary.no_hours', { ITEM: itemType })}
        </span>
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
};

const PacksSummaryWrapper: React.FC<PacksSummaryProps> = (props) => {
  return (
    <Loader>
      <PacksSummary {...props} />
    </Loader>
  );
};

export { PacksSummaryWrapper as PacksSummary };

Application.Components.component('packsSummary', react2angular(PacksSummaryWrapper, ['item', 'itemType', 'customer', 'operator', 'onError', 'onSuccess', 'refresh']));
