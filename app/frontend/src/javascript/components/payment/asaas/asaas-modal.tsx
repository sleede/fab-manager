import { useEffect, useMemo, useRef, useState } from 'react';
import * as React from 'react';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from '../../base/fab-modal';
import { Loader } from '../../base/loader';
import { ShoppingCart } from '../../../models/payment';
import { User } from '../../../models/user';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { Invoice } from '../../../models/invoice';
import { Order } from '../../../models/order';
import WalletAPI from '../../../api/wallet';
import PriceAPI from '../../../api/price';
import WalletLib from '../../../lib/wallet';
import { WalletInfo } from '../wallet-info';
import { Wallet } from '../../../models/wallet';
import { ComputePriceResult } from '../../../models/price';
import { computePriceWithCoupon } from '../../../lib/coupon';
import FormatLib from '../../../lib/format';
import AsaasAPI from '../../../api/asaas';
import { AsaasPayment } from '../../../models/asaas';
import { IApplication } from '../../../models/application';
import { FabInput } from '../../base/fab-input';

declare const Application: IApplication;

interface AsaasModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule|Order) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  order?: Order,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User,
}

const isAsaasPayment = (value: AsaasPayment|Invoice|Order): value is AsaasPayment => {
  return Object.prototype.hasOwnProperty.call(value, 'token');
};

const normalizeCpf = (value: string): string => value.replace(/\D/g, '').slice(0, 11);

const formatCpf = (value: string): string => {
  const cpf = normalizeCpf(value);
  if (cpf.length <= 3) return cpf;
  if (cpf.length <= 6) return cpf.replace(/(\d{3})(\d+)/, '$1.$2');
  if (cpf.length <= 9) return cpf.replace(/(\d{3})(\d{3})(\d+)/, '$1.$2.$3');
  return cpf.replace(/(\d{3})(\d{3})(\d{3})(\d{0,2})/, '$1.$2.$3-$4');
};

const isValidCpf = (value: string): boolean => {
  const cpf = normalizeCpf(value);
  if (!cpf.match(/^\d{11}$/) || /^([0-9])\1+$/.test(cpf)) return false;

  const digits = cpf.split('').map(Number);
  const verifier = (base: number[], factor: number): number => {
    const sum = base.reduce((acc, digit, index) => acc + (digit * (factor - index)), 0);
    const mod = (sum * 10) % 11;
    return mod === 10 ? 0 : mod;
  };

  return digits[9] === verifier(digits.slice(0, 9), 10) && digits[10] === verifier(digits.slice(0, 10), 11);
};

const MINIMUM_PIX_AMOUNT = 5;

/**
 * Displays the Pix payment flow for Asaas.
 */
const AsaasModal: React.FC<AsaasModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, cart, order, currentUser, schedule }) => {
  const { t } = useTranslation('shared');
  const [wallet, setWallet] = useState<Wallet>(null);
  const [price, setPrice] = useState<ComputePriceResult>(null);
  const [remainingPrice, setRemainingPrice] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(false);
  const [payment, setPayment] = useState<AsaasPayment>(null);
  const [cpf, setCpf] = useState<string>('');
  const intervalRef = useRef<number>(null);

  useEffect(() => {
    if (!isOpen) return;

    setPayment(null);
    setLoading(false);
    setCpf('');

    if (schedule) {
      onError(t('app.shared.asaas_modal.payment_schedule_not_supported'));
      toggleModal();
      return;
    }

    if (order?.user?.id) {
      WalletAPI.getByUser(order.user.id).then((wallet) => {
        setWallet(wallet);
        const p = { price: computePriceWithCoupon(order.total, order.coupon), price_without_coupon: order.total };
        setPrice(p);
        setRemainingPrice(new WalletLib(wallet).computeRemainingPrice(p.price));
      }).catch(onError);
    } else {
      WalletAPI.getByUser(cart.customer_id).then((wallet) => {
        setWallet(wallet);
        return PriceAPI.compute(cart).then((computed) => {
          setPrice(computed);
          setRemainingPrice(new WalletLib(wallet).computeRemainingPrice(computed.price));
        });
      }).catch(onError);
    }

    return () => {
      if (intervalRef.current) window.clearInterval(intervalRef.current);
    };
  }, [isOpen]);

  const qrImage = useMemo(() => {
    if (!payment?.pix_encoded_image) return null;
    return `data:image/png;base64,${payment.pix_encoded_image}`;
  }, [payment]);

  const cpfIsValid = useMemo(() => isValidCpf(cpf), [cpf]);
  const belowMinimumPixAmount = useMemo(() => remainingPrice > 0 && remainingPrice < MINIMUM_PIX_AMOUNT, [remainingPrice]);

  /**
   * Poll the payment status until the backend confirms completion.
   */
  const startPolling = (token: string): void => {
    if (intervalRef.current) window.clearInterval(intervalRef.current);
    intervalRef.current = window.setInterval(async () => {
      try {
        const result = await AsaasAPI.paymentStatus(token);
        if (isAsaasPayment(result)) {
          setPayment(result);
          if (result.status === 'expired') {
            window.clearInterval(intervalRef.current);
            setLoading(false);
          }
        } else {
          window.clearInterval(intervalRef.current);
          setLoading(false);
          afterSuccess(result);
        }
      } catch (error) {
        window.clearInterval(intervalRef.current);
        setLoading(false);
        onError(String(error));
      }
    }, 4000);
  };

  /**
   * Create a new Pix payment and start polling its status.
   */
  const createPayment = async (): Promise<void> => {
    if (!cpfIsValid) {
      onError(t('app.shared.asaas_modal.invalid_cpf'));
      return;
    }

    if (belowMinimumPixAmount) {
      onError(t('app.shared.asaas_modal.minimum_amount_error', { AMOUNT: FormatLib.price(MINIMUM_PIX_AMOUNT) }));
      return;
    }

    setLoading(true);
    try {
      const result = order ? await AsaasAPI.createOrderPayment(order, normalizeCpf(cpf)) : await AsaasAPI.createCartPayment(cart, normalizeCpf(cpf));
      setPayment(result);
      setLoading(false);
      startPolling(result.token);
    } catch (error) {
      setLoading(false);
      onError(String(error));
    }
  };

  return (
    <FabModal title={t('app.shared.asaas_modal.title')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.medium}
      className="payment-modal asaas-modal">
      {!!price && <div>
        {!!cart && <WalletInfo cart={cart} currentUser={currentUser} wallet={wallet} price={price.price} />}
        {!payment && <div className="asaas-intro">
          <p>{t('app.shared.asaas_modal.description')}</p>
          <div className="asaas-cpf-field">
            <label htmlFor="asaas_cpf">{t('app.shared.asaas_modal.cpf')}</label>
            <FabInput id="asaas_cpf"
              type="text"
              defaultValue={cpf}
              placeholder={t('app.shared.asaas_modal.cpf_placeholder')}
              maxLength={14}
              required
              onChange={(value) => setCpf(formatCpf(String(value)))} />
            {!cpfIsValid && cpf.length > 0 && <p className="asaas-cpf-error">{t('app.shared.asaas_modal.invalid_cpf')}</p>}
            {belowMinimumPixAmount && <p className="asaas-cpf-error">{t('app.shared.asaas_modal.minimum_amount_error', { AMOUNT: FormatLib.price(MINIMUM_PIX_AMOUNT) })}</p>}
          </div>
          <button type="button" className="validate-btn" disabled={loading || remainingPrice <= 0 || !cpfIsValid || belowMinimumPixAmount} onClick={createPayment}>
            {t('app.shared.asaas_modal.generate_pix_of_AMOUNT', { AMOUNT: FormatLib.price(remainingPrice) })}
          </button>
        </div>}
        {loading && <div className="payment-pending"><div className="fa-2x"><i className="fas fa-circle-notch fa-spin" /></div></div>}
        {payment && <div className="asaas-payment-state">
          <p>{t('app.shared.asaas_modal.waiting_payment')}</p>
          {qrImage && <img className="asaas-qr-code" src={qrImage} alt={t('app.shared.asaas_modal.qr_code_alt')} />}
          <label htmlFor="asaas_pix_payload">{t('app.shared.asaas_modal.copy_and_paste')}</label>
          <textarea id="asaas_pix_payload" readOnly value={payment.pix_payload} className="asaas-pix-payload" rows={5} />
          {payment.pix_expiration_at && <p>{t('app.shared.asaas_modal.expires_at', { DATE: `${FormatLib.date(new Date(payment.pix_expiration_at))} ${FormatLib.time(new Date(payment.pix_expiration_at))}` })}</p>}
          {payment.status === 'expired' && <p className="asaas-payment-expired">{t('app.shared.asaas_modal.payment_expired')}</p>}
        </div>}
      </div>}
    </FabModal>
  );
};

const AsaasModalWrapper: React.FC<AsaasModalProps> = (props) => (
  <Loader>
    <AsaasModal {...props} />
  </Loader>
);

export { AsaasModalWrapper as AsaasModal };

Application.Components.component('asaasModal', react2angular(AsaasModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'onError', 'currentUser', 'schedule', 'cart', 'customer', 'order']));
