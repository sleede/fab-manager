import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabInput } from '../base/fab-input';
import { FabAlert } from '../base/fab-alert';
import CouponAPI from '../../api/coupon';
import { Coupon } from '../../models/coupon';
import { User } from '../../models/user';
import FormatLib from '../../lib/format';

interface CouponInputProps {
  amount: number,
  user?: User,
  onChange?: (coupon?: Coupon) => void
}

interface Message {
  type: 'info' | 'warning' | 'danger',
  message: string
}

/**
 * This component renders an input of coupon
 */
export const CouponInput: React.FC<CouponInputProps> = ({ user, amount, onChange }) => {
  const { t } = useTranslation('shared');
  const [messages, setMessages] = useState<Array<Message>>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<boolean>(false);
  const [coupon, setCoupon] = useState<Coupon>();
  const [code, setCode] = useState<string>();

  useEffect(() => {
    if (user && code) {
      handleChange(code);
    }
  }, [user?.id]);

  useEffect(() => {
    if (code) {
      handleChange(code);
    }
  }, [amount]);

  /**
   * callback for validate the code
   */
  const handleChange = (value: string) => {
    const mgs = [];
    setMessages([]);
    setError(false);
    setCoupon(null);
    setCode(value);
    if (value) {
      setLoading(true);
      CouponAPI.validate(value, amount, user?.id).then((res) => {
        setCoupon(res);
        if (res.type === 'percent_off') {
          mgs.push({ type: 'info', message: t('app.shared.coupon_input.the_coupon_has_been_applied_you_get_PERCENT_discount', { PERCENT: res.percent_off }) });
        } else {
          mgs.push({ type: 'info', message: t('app.shared.coupon_input.the_coupon_has_been_applied_you_get_AMOUNT_CURRENCY', { AMOUNT: res.amount_off, CURRENCY: FormatLib.currencySymbol() }) });
        }
        if (res.validity_per_user === 'once') {
          mgs.push({ type: 'warning', message: t('app.shared.coupon_input.coupon_validity_once') });
        }
        setMessages(mgs);
        setLoading(false);
        if (typeof onChange === 'function') {
          onChange(res);
        }
      }).catch((err) => {
        const state = err.split(':')[1].trim();
        setError(true);
        setCoupon(null);
        setLoading(false);
        setMessages([{ type: 'danger', message: t(`app.shared.coupon_input.unable_to_apply_the_coupon_because_${state}`) }]);
        onChange(null);
      });
    } else {
      onChange(null);
    }
  };

  // input addon
  const inputAddOn = () => {
    if (error) {
      return <i className="fa fa-times" />;
    } else {
      if (loading) {
        return <i className="fa fa-spinner fa-pulse fa-fw" />;
      }
      if (coupon) {
        return <i className="fa fa-check" />;
      }
    }
  };

  return (
    <div className="coupon-input">
      <label htmlFor="coupon-input_input">{t('app.shared.coupon_input.i_have_a_coupon')}</label>
      <FabInput id="coupon-input_input"
                type="text"
                addOn={inputAddOn()}
                debounce={500}
                onChange={handleChange} />
      {messages.map((m, i) => {
        return (
          <FabAlert key={i} level={m.type}>
            {m.message}
          </FabAlert>
        );
      })}
    </div>
  );
};
