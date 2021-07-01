import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';
import '../lib/i18n';
import { Loader } from './base/loader';
import { User } from '../models/user';
import { Wallet } from '../models/wallet';
import WalletLib from '../lib/wallet';
import { ShoppingCart } from '../models/payment';
import FormatLib from '../lib/format';

declare const Application: IApplication;

interface WalletInfoProps {
  cart: ShoppingCart,
  currentUser: User,
  wallet: Wallet,
  price: number,
}

/**
 * This component displays a summary of the amount paid with the virtual wallet, for the current transaction
 */
export const WalletInfo: React.FC<WalletInfoProps> = ({ cart, currentUser, wallet, price }) => {
  const { t } = useTranslation('shared');
  const [remainingPrice, setRemainingPrice] = useState(0);

  /**
   * Refresh the remaining price on each display
   */
  useEffect(() => {
    const wLib = new WalletLib(wallet);
    setRemainingPrice(wLib.computeRemainingPrice(price));
  });

  /**
   * Check if the currently connected used is also the person making the reservation.
   * If the currently connected user (i.e. the operator), is an admin or a manager, he may book the reservation for someone else.
   */
  const isOperatorAndClient = (): boolean => {
    return currentUser.id === cart.customer_id;
  };
  /**
   * If the client has some money in his wallet & the price is not zero, then we should display this component.
   */
  const shouldBeShown = (): boolean => {
    return wallet.amount > 0 && price > 0;
  };
  /**
   * If the amount in the wallet is not enough to cover the whole price, then the user must pay the remaining price
   * using another payment mean.
   */
  const hasRemainingPrice = (): boolean => {
    return remainingPrice > 0;
  };
  /**
   * Does the current cart contains a payment schedule?
   */
  const isPaymentSchedule = (): boolean => {
    return cart.items.find(i => 'subscription' in i) && cart.payment_schedule;
  };
  /**
   * Return the human-readable name of the item currently bought with the wallet
   */
  const getPriceItem = (): string => {
    let item = 'other';
    if (cart.items.find(i => 'reservation' in i)) {
      item = 'reservation';
    } else if (cart.items.find(i => 'subscription' in i)) {
      if (cart.payment_schedule) {
        item = 'first_deadline';
      } else item = 'subscription';
    }

    return t(`app.shared.wallet.wallet_info.item_${item}`);
  };

  return (
    <div className="wallet-info">
      {shouldBeShown() && <div>
        {isOperatorAndClient() && <div>
          <h3>{t('app.shared.wallet.wallet_info.you_have_AMOUNT_in_wallet', { AMOUNT: FormatLib.price(wallet.amount) })}</h3>
          {!hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.wallet_pay_ITEM', { ITEM: getPriceItem() })}
          </p>}
          {hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.credit_AMOUNT_for_pay_ITEM', {
              AMOUNT: FormatLib.price(remainingPrice),
              ITEM: getPriceItem()
            })}
          </p>}
        </div>}
        {!isOperatorAndClient() && <div>
          <h3>{t('app.shared.wallet.wallet_info.client_have_AMOUNT_in_wallet', { AMOUNT: FormatLib.price(wallet.amount) })}</h3>
          {!hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.client_wallet_pay_ITEM', { ITEM: getPriceItem() })}
          </p>}
          {hasRemainingPrice() && <p>
            {t('app.shared.wallet.wallet_info.client_credit_AMOUNT_for_pay_ITEM', {
              AMOUNT: FormatLib.price(remainingPrice),
              ITEM: getPriceItem()
            })}
          </p>}
        </div>}
        {!hasRemainingPrice() && isPaymentSchedule() && <p className="info-deadlines">
          <i className="fa fa-warning"/>
          <span>{t('app.shared.wallet.wallet_info.other_deadlines_no_wallet')}</span>
        </p>}
      </div>}
    </div>
  );
};

const WalletInfoWrapper: React.FC<WalletInfoProps> = ({ currentUser, cart, price, wallet }) => {
  return (
    <Loader>
      <WalletInfo currentUser={currentUser} cart={cart} price={price} wallet={wallet}/>
    </Loader>
  );
};

Application.Components.component('walletInfo', react2angular(WalletInfoWrapper, ['currentUser', 'price', 'cart', 'wallet']));
