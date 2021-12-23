import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../../base/loader';
import { FabAlert } from '../../base/fab-alert';
import { HtmlTranslate } from '../../base/html-translate';
import SpaceAPI from '../../../api/space';
import GroupAPI from '../../../api/group';
import { Group } from '../../../models/group';
import { IApplication } from '../../../models/application';
import { Space } from '../../../models/space';
import { EditablePrice } from '../editable-price';
import { ConfigureExtendedPriceButton } from './configure-extended-price-button';
import PriceAPI from '../../../api/price';
import { Price } from '../../../models/price';
import { useImmer } from 'use-immer';
import FormatLib from '../../../lib/format';

declare const Application: IApplication;

interface SpacesPricingProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Interface to set and edit the prices of spaces-hours, per group
 */
const SpacesPricing: React.FC<SpacesPricingProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [spaces, setSpaces] = useState<Array<Space>>(null);
  const [groups, setGroups] = useState<Array<Group>>(null);
  const [prices, updatePrices] = useImmer<Array<Price>>([]);

  // retrieve the initial data
  useEffect(() => {
    SpaceAPI.index()
      .then(data => setSpaces(data))
      .catch(error => onError(error));
    GroupAPI.index({ disabled: false, admins: false })
      .then(data => setGroups(data))
      .catch(error => onError(error));
    PriceAPI.index({ priceable_type: 'Space', plan_id: null })
      .then(data => updatePrices(data))
      .catch(error => onError(error));
  }, []);

  // duration of the example slot
  const EXEMPLE_DURATION = 20;

  /**
   * Return the exemple price, formatted
   */
  const examplePrice = (type: 'hourly_rate' | 'final_price'): string => {
    const hourlyRate = 10;

    if (type === 'hourly_rate') {
      return FormatLib.price(hourlyRate);
    }

    const price = (hourlyRate / 60) * EXEMPLE_DURATION;
    return FormatLib.price(price);
  };

  /**
   * Find the default price (hourly rate) matching the given criterion
   */
  const findPriceBy = (spaceId, groupId): Price => {
    return prices.find(price => price.priceable_id === spaceId && price.group_id === groupId && price.duration === 60);
  };

  /**
   * Find prices matching the given criterion, except the default hourly rate
   */
  const findExtendedPricesBy = (spaceId, groupId): Array<Price> => {
    return prices.filter(price => price.priceable_id === spaceId && price.group_id === groupId && price.duration !== 60);
  };

  /**
   * Update the given price in the internal state
   */
  const updatePrice = (price: Price): void => {
    updatePrices(draft => {
      const index = draft.findIndex(p => p.id === price.id);
      draft[index] = price;
      return draft;
    });
  };

  /**
   * Callback triggered when the user has confirmed to update a price
   */
  const handleUpdatePrice = (price: Price): void => {
    PriceAPI.update(price)
      .then(() => {
        onSuccess(t('app.admin.spaces_pricing.price_updated'));
        updatePrice(price);
      })
      .catch(error => onError(error));
  };

  return (
    <div className="pricing-list">
      <FabAlert level="warning">
        <p><HtmlTranslate trKey="app.admin.pricing.these_prices_match_space_hours_rates_html"/></p>
        <p><HtmlTranslate trKey="app.admin.pricing.prices_calculated_on_hourly_rate_html" options={{ DURATION: `${EXEMPLE_DURATION}`, RATE: examplePrice('hourly_rate'), PRICE: examplePrice('final_price') }} /></p>
        <p>{t('app.admin.pricing.you_can_override')}</p>
      </FabAlert>
      <table>
        <thead>
          <tr>
            <th>{t('app.admin.pricing.spaces')}</th>
            {groups?.map(group => <th key={group.id} className="group-name">{group.name}</th>)}
          </tr>
        </thead>
        <tbody>
          {spaces?.map(space => <tr key={space.id}>
            <td>{space.name}</td>
            {groups?.map(group => <td key={group.id}>
              {prices.length && <EditablePrice price={findPriceBy(space.id, group.id)} onSave={handleUpdatePrice} />}
              <ConfigureExtendedPriceButton
                prices={findExtendedPricesBy(space.id, group.id)}
                onError={onError}
                onSuccess={onSuccess}
                groupId={group.id}
                priceableId={space.id}
                priceableType='Space' />
            </td>)}
          </tr>)}
        </tbody>
      </table>
    </div>
  );
};

const SpacesPricingWrapper: React.FC<SpacesPricingProps> = ({ onError, onSuccess }) => {
  return (
    <Loader>
      <SpacesPricing onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('spacesPricing', react2angular(SpacesPricingWrapper, ['onError', 'onSuccess']));
