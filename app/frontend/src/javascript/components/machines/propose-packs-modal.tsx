import React, { BaseSyntheticEvent, useEffect, useState } from 'react';
import { Machine } from '../../models/machine';
import { FabModal, ModalSize } from '../base/fab-modal';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { User } from '../../models/user';
import { PrepaidPack } from '../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { IFablab } from '../../models/fablab';
import { FabButton } from '../base/fab-button';
import PriceAPI from '../../api/price';
import { Price } from '../../models/price';

declare var Fablab: IFablab;

interface ProposePacksModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  machine: Machine,
  customer: User,
  onError: (message: string) => void,
  onDecline: (machine: Machine) => void,
}

/**
 * Modal dialog shown to offer prepaid-packs for purchase, to the current user.
 */
export const ProposePacksModal: React.FC<ProposePacksModalProps> = ({ isOpen, toggleModal, machine, customer, onError, onDecline }) => {
  const { t } = useTranslation('logged');

  const [price, setPrice] = useState<Price>(null);
  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);

  useEffect(() => {
    PrepaidPackAPI.index({ priceable_id: machine.id, priceable_type: 'Machine', group_id: customer.group_id, disabled: false })
      .then(data => setPacks(data))
      .catch(error => onError(error));
    PriceAPI.index({ priceable_id: machine.id, priceable_type: 'Machine', group_id: customer.group_id, plan_id: null })
      .then(data => setPrice(data[0]))
      .catch(error => onError(error));
  }, [machine]);


  /**
   * Return the formatted localized amount for the given price (e.g. 20.5 => "20,50 €")
   */
  const formatPrice = (price: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).format(price);
  }

  /**
   * Convert the hourly-based price of the given prive, to a total price, based on the duration of the given pack
   */
  const hourlyPriceToTotal = (price: Price, pack: PrepaidPack): number => {
    const hours = pack.minutes / 60;
    return price.amount * hours;
  }

  /**
   * Return the number of hours, user-friendly formatted
   */
  const formatDuration = (minutes: number): string => {
    return t('app.logged.propose_packs_modal.pack_DURATION', { DURATION: minutes / 60 });
  }
  /**
   * The user has declined to buy a pack
   */
  const handlePacksRefused = (): void => {
    onDecline(machine);
  }

  /**
   * The user has accepted to buy the provided pack, process with teh payment
   */
  const handleBuyPack = (pack: PrepaidPack) => {
    return (event: BaseSyntheticEvent): void => {
      console.log(pack);
    }
  }

  /**
   * Render the given prepaid-pack
   */
  const renderPack = (pack: PrepaidPack) => {
    if (!price) return;

    const normalPrice = hourlyPriceToTotal(price, pack)
    return (
      <div key={pack.id} className="pack">
        <span className="duration">{formatDuration(pack.minutes)}</span>
        <span className="amount">{formatPrice(pack.amount)}</span>
        {pack.amount < normalPrice && <span className="crossed-out-price">{formatPrice(normalPrice)}</span>}
        <FabButton className="buy-button" onClick={handleBuyPack(pack)} icon={<i className="fas fa-shopping-cart" />}>
          {t('app.logged.propose_packs_modal.buy_this_pack')}
        </FabButton>
      </div>
    )
  }

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.large}
              confirmButton={t('app.logged.propose_packs_modal.no_thanks')}
              onConfirm={handlePacksRefused}
              className="propose-packs-modal"
              title={t('app.logged.propose_packs_modal.available_packs')}>
      <p>{t('app.logged.propose_packs_modal.packs_proposed')}</p>
      <div className="list-of-packs">
        {packs?.map(p => renderPack(p))}
      </div>
    </FabModal>
  );
}
