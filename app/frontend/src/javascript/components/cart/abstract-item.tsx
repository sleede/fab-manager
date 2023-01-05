import * as React from 'react';
import noImage from '../../../../images/no_image.png';
import FormatLib from '../../lib/format';
import OrderLib from '../../lib/order';
import { FabButton } from '../base/fab-button';
import Switch from 'react-switch';
import type { OrderItem } from '../../models/order';
import { useTranslation } from 'react-i18next';
import { ReactNode } from 'react';

interface AbstractItemProps {
  item: OrderItem,
  hasError: boolean,
  className?: string,
  removeItemFromCart: (item: OrderItem) => void,
  toggleItemOffer: (item: OrderItem, checked: boolean) => void,
  privilegedOperator: boolean,
  actions?: ReactNode
}

/**
 * This component shares the common code for items in the cart (product, cart-item, etc)
 */
export const AbstractItem: React.FC<AbstractItemProps> = ({ item, hasError, className, removeItemFromCart, toggleItemOffer, privilegedOperator, actions, children }) => {
  const { t } = useTranslation('public');

  /**
   * Return the callback triggered when then user remove the given item from the cart
   */
  const handleRemoveItem = (item: OrderItem) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();

      removeItemFromCart(item);
    };
  };

  /**
   * Return the callback triggered when the privileged user enable/disable the offered attribute for the given item
   */
  const handleToggleOffer = (item: OrderItem) => {
    return (checked: boolean) => toggleItemOffer(item, checked);
  };

  return (
    <article className={`item ${className || ''} ${hasError ? 'error' : ''}`}>
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
        <FabButton className="main-action-btn" onClick={handleRemoveItem(item)}>
          <i className="fa fa-trash" />
        </FabButton>
      </div>
      {privilegedOperator &&
        <div className='offer'>
          <label>
            <span>{t('app.public.abstract_item.offer_product')}</span>
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
