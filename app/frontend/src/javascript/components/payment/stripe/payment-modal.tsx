import { Invoice } from '../../../models/invoice';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { ShoppingCart } from '../../../models/payment';
import { User } from '../../../models/user';
import React, { useEffect, useState } from 'react';
import WalletAPI from '../../../api/wallet';
import { Wallet } from '../../../models/wallet';
import WalletLib from '../../../lib/wallet';
import UserLib from '../../../lib/user';
import { LocalPaymentModal } from '../local-payment/local-payment-modal';
import { CardPaymentModal } from '../card-payment-modal';
import PriceAPI from '../../../api/price';
import { ComputePriceResult } from '../../../models/price';

interface PaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  updateCart: (cart: ShoppingCart) => void,
  operator: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component is responsible for rendering the payment modal.
 */
export const PaymentModal: React.FC<PaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, cart, updateCart, operator, schedule, customer }) => {
  // the user's wallet
  const [wallet, setWallet] = useState<Wallet>(null);
  // the price of the cart
  const [price, setPrice] = useState<ComputePriceResult>(null);
  // the remaining price to pay, after the wallet was changed
  const [remainingPrice, setRemainingPrice] = useState<number>(null);

  // refresh the wallet when the customer changes
  useEffect(() => {
    WalletAPI.getByUser(customer.id).then(wallet => {
      setWallet(wallet);
    });
  }, [customer]);

  // refresh the price when the cart changes
  useEffect(() => {
    PriceAPI.compute(cart).then(price => {
      setPrice(price);
    });
  }, [cart]);

  // refresh the remaining price when the cart price was computed and the wallet was retrieved
  useEffect(() => {
    if (price && wallet) {
      setRemainingPrice(new WalletLib(wallet).computeRemainingPrice(price?.price));
    }
  }, [price, wallet]);

  /**
   * Check the conditions for the local payment
   */
  const isLocalPayment = (): boolean => {
    return (new UserLib(operator).isPrivileged(customer) || remainingPrice === 0);
  };

  // do not render the modal until the real remaining price is computed
  if (remainingPrice === null) return null;

  if (isLocalPayment()) {
    return (
      <LocalPaymentModal isOpen={isOpen}
        toggleModal={toggleModal}
        afterSuccess={afterSuccess}
        onError={onError}
        cart={cart}
        updateCart={updateCart}
        currentUser={operator}
        customer={customer}
        schedule={schedule}
      />
    );
  } else {
    return (
      <CardPaymentModal isOpen={isOpen}
        toggleModal={toggleModal}
        afterSuccess={afterSuccess}
        onError={onError}
        cart={cart}
        currentUser={operator}
        customer={customer}
        schedule={schedule}
      />
    );
  }
};
