import React, { useEffect, useState } from 'react';
import { Machine } from '../../models/machine';
import { FabModal, ModalSize } from '../base/fab-modal';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { User } from '../../models/user';
import { PrepaidPack } from '../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import PriceAPI from '../../api/price';
import { Price } from '../../models/price';
import { PaymentMethod, ShoppingCart } from '../../models/payment';
import { PaymentModal } from '../payment/payment-modal';
import UserLib from '../../lib/user';
import { LocalPaymentModal } from '../payment/local-payment/local-payment-modal';
import FormatLib from '../../lib/format';

type PackableItem = Machine;

interface ProposePacksModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  item: PackableItem,
  itemType: 'Machine',
  customer: User,
  operator: User,
  onError: (message: string) => void,
  onDecline: (item: PackableItem) => void,
  onSuccess: (message:string, item: PackableItem) => void,
}

/**
 * Modal dialog shown to offer prepaid-packs for purchase, to the current user.
 */
export const ProposePacksModal: React.FC<ProposePacksModalProps> = ({ isOpen, toggleModal, item, itemType, customer, operator, onError, onDecline, onSuccess }) => {
  const { t } = useTranslation('logged');

  const [price, setPrice] = useState<Price>(null);
  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);
  const [cart, setCart] = useState<ShoppingCart>(null);
  const [paymentModal, setPaymentModal] = useState<boolean>(false);
  const [localPaymentModal, setLocalPaymentModal] = useState<boolean>(false);

  useEffect(() => {
    PrepaidPackAPI.index({ priceable_id: item.id, priceable_type: itemType, group_id: customer.group_id, disabled: false })
      .then(data => setPacks(data))
      .catch(error => onError(error));
    PriceAPI.index({ priceable_id: item.id, priceable_type: itemType, group_id: customer.group_id, plan_id: null })
      .then(data => setPrice(data[0]))
      .catch(error => onError(error));
  }, [item]);

  /**
   * Open/closes the payment modal
   */
  const togglePaymentModal = (): void => {
    setPaymentModal(!paymentModal);
  };

  /**
   * Open/closes the local payment modal (for admins and managers)
   */
  const toggleLocalPaymentModal = (): void => {
    setLocalPaymentModal(!localPaymentModal);
  };

  /**
   * Convert the hourly-based price of the given prive, to a total price, based on the duration of the given pack
   */
  const hourlyPriceToTotal = (price: Price, pack: PrepaidPack): number => {
    const hours = pack.minutes / 60;
    return price.amount * hours;
  };

  /**
   * Return the number of hours, user-friendly formatted
   */
  const formatDuration = (minutes: number): string => {
    return t('app.logged.propose_packs_modal.pack_DURATION', { DURATION: minutes / 60 });
  };

  /**
   * Return a user-friendly string for the validity of the provided pack
   */
  const formatValidity = (pack: PrepaidPack): string => {
    const period = t(`app.logged.propose_packs_modal.period.${pack.validity_interval}`, { COUNT: pack.validity_count });
    return t('app.logged.propose_packs_modal.validity', { COUNT: pack.validity_count, PERIODS: period });
  };

  /**
   * The user has declined to buy a pack
   */
  const handlePacksRefused = (): void => {
    onDecline(item);
  };

  /**
   * The user has accepted to buy the provided pack, process with the payment
   */
  const handleBuyPack = (pack: PrepaidPack) => {
    return (): void => {
      setCart({
        customer_id: customer.id,
        payment_method: PaymentMethod.Card,
        items: [
          { prepaid_pack: { id: pack.id } }
        ]
      });
      if (new UserLib(operator).isPrivileged(customer)) {
        return toggleLocalPaymentModal();
      }
      togglePaymentModal();
    };
  };

  /**
   * Callback triggered when the user has bought the pack with a successful payment
   */
  const handlePackBought = (): void => {
    onSuccess(t('app.logged.propose_packs_modal.pack_bought_success'), item);
  };

  /**
   * Render the given prepaid-pack
   */
  const renderPack = (pack: PrepaidPack) => {
    if (!price) return;

    const normalPrice = hourlyPriceToTotal(price, pack);
    return (
      <div key={pack.id} className="pack">
        <span className="duration">{formatDuration(pack.minutes)}</span>
        <span className="amount">{FormatLib.price(pack.amount)}</span>
        {pack.amount < normalPrice && <span className="crossed-out-price">{FormatLib.price(normalPrice)}</span>}
        <span className="validity">{formatValidity(pack)}</span>
        <FabButton className="buy-button" onClick={handleBuyPack(pack)} icon={<i className="fas fa-shopping-cart" />}>
          {t('app.logged.propose_packs_modal.buy_this_pack')}
        </FabButton>
      </div>
    );
  };

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
      {cart && <div>
        <PaymentModal isOpen={paymentModal}
          toggleModal={togglePaymentModal}
          afterSuccess={handlePackBought}
          onError={onError}
          cart={cart}
          currentUser={operator}
          customer={customer} />
        <LocalPaymentModal isOpen={localPaymentModal}
          toggleModal={toggleLocalPaymentModal}
          afterSuccess={handlePackBought}
          cart={cart}
          currentUser={operator}
          customer={customer} />
      </div>}
    </FabModal>
  );
};
