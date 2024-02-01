import * as React from 'react';
import noImage from '../../../../images/no_image.png';
import FormatLib from '../../lib/format';
import OrderLib from '../../lib/order';
import { FabButton } from '../base/fab-button';
import Switch from 'react-switch';
import type { ItemError, OrderItem } from '../../models/order';
import { useTranslation } from 'react-i18next';
import { ReactNode } from 'react';
import { Order } from '../../models/order';
import CartAPI from '../../api/cart';

interface AbstractItemProps {
  item: OrderItem,
  errors: Array<ItemError>,
  cart: Order,
  setCart: (cart: Order) => void,
  reloadCart: () => Promise<void>,
  onError: (message: string) => void,
  className?: string,
  offerItemLabel?: string,
  privilegedOperator: boolean,
  actions?: ReactNode
}

/**
 * This component shares the common code for items in the cart (product, cart-item, etc)
 */
export const AbstractItem: React.FC<AbstractItemProps> = ({ item, errors, cart, setCart, reloadCart, onError, className, offerItemLabel, privilegedOperator, actions, children }) => {
  const { t } = useTranslation('public');

  /**
   * Return the callback triggered when then user remove the given item from the cart
   */
  const handleRemoveItem = (item: OrderItem) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();

      if (errors.length === 1 && errors[0].error === 'not_found') {
        reloadCart().catch(onError);
      } else {
        CartAPI.removeItem(cart, item.orderable_id, item.orderable_type).then(data => {
          setCart(data);
        }).catch(onError);
      }
    };
  };

  /**
   * Return the callback triggered when the privileged user enable/disable the offered attribute for the given item
   */
  const handleToggleOffer = (item: OrderItem) => {
    return (checked: boolean) => {
      CartAPI.setOffer(cart, item.orderable_id, item.orderable_type, checked).then(data => {
        setCart(data);
      }).catch(e => {
        if (e.match(/code 403/)) {
          onError(t('app.public.abstract_item.errors.unauthorized_offering_product'));
        } else {
          onError(e);
        }
      });
    };
  };

  return (
    <article className={`item ${className || ''} ${errors.length > 0 ? 'error' : ''}`}>
      <div className='picture'>
        <img alt='' src={item.orderable_main_image_url || noImage} />
      </div>
      {children}
      <div className="actions">
        {actions}
        <div className='total'>
          <span>{t('app.public.abstract_item.total')}</span>
          <p>{FormatLib.price(OrderLib.itemAmount(item))}</p>
        </div>
        <FabButton className="is-alert" onClick={handleRemoveItem(item)}>
          <i className="fa fa-trash" />
        </FabButton>
      </div>
      {privilegedOperator &&
        <div className='offer'>
          <label>
            <span>{offerItemLabel || t('app.public.abstract_item.offer_product')}</span>
            <Switch
              checked={item.is_offered || false}
              onChange={handleToggleOffer(item)}
              width={40}
              height={19}
              uncheckedIcon={false}
              checkedIcon={false}
              handleDiameter={15} />
          </label>
        </div>
      }
    </article>
  );
};
