import { useEffect, useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../../base/loader';
import { FabAlert } from '../../base/fab-alert';
import { HtmlTranslate } from '../../base/html-translate';
import MachineAPI from '../../../api/machine';
import GroupAPI from '../../../api/group';
import { Machine } from '../../../models/machine';
import { Group } from '../../../models/group';
import { IApplication } from '../../../models/application';
import { EditablePrice } from '../editable-price';
import { ConfigurePacksButton } from './configure-packs-button';
import PriceAPI from '../../../api/price';
import { Price } from '../../../models/price';
import PrepaidPackAPI from '../../../api/prepaid-pack';
import { PrepaidPack } from '../../../models/prepaid-pack';
import { useImmer } from 'use-immer';
import FormatLib from '../../../lib/format';

declare const Application: IApplication;

interface MachinesPricingProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Interface to set and edit the prices of machines-hours, per group
 */
export const MachinesPricing: React.FC<MachinesPricingProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [machines, setMachines] = useState<Array<Machine>>(null);
  const [groups, setGroups] = useState<Array<Group>>(null);
  const [prices, updatePrices] = useImmer<Array<Price>>(null);
  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);

  // retrieve the initial data
  useEffect(() => {
    MachineAPI.index({ disabled: false })
      .then(data => setMachines(data))
      .catch(error => onError(error));
    GroupAPI.index({ disabled: false })
      .then(data => setGroups(data))
      .catch(error => onError(error));
    PriceAPI.index({ priceable_type: 'Machine', plan_id: null })
      .then(data => updatePrices(data))
      .catch(error => onError(error));
    PrepaidPackAPI.index()
      .then(data => setPacks(data))
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
   * Find the price matching the given criterion
   */
  const findPriceBy = (machineId, groupId): Price => {
    return prices.find(price => price.priceable_id === machineId && price.group_id === groupId);
  };

  /**
   * Filter the packs matching the given criterion
   */
  const filterPacksBy = (machineId, groupId): Array<PrepaidPack> => {
    return packs.filter(pack => pack.priceable_id === machineId && pack.group_id === groupId);
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
        onSuccess(t('app.admin.machines_pricing.price_updated'));
        updatePrice(price);
      })
      .catch(error => onError(error));
  };

  return (
    <div className="machines-pricing">
      <FabAlert level="warning">
        <p><HtmlTranslate trKey="app.admin.machines_pricing.prices_match_machine_hours_rates_html"/></p>
        <p><HtmlTranslate trKey="app.admin.machines_pricing.prices_calculated_on_hourly_rate_html" options={{ DURATION: `${EXEMPLE_DURATION}`, RATE: examplePrice('hourly_rate'), PRICE: examplePrice('final_price') }} /></p>
        <p>{t('app.admin.machines_pricing.you_can_override')}</p>
      </FabAlert>
      <table>
        <thead>
          <tr>
            <th>{t('app.admin.machines_pricing.machines')}</th>
            {groups?.map(group => <th key={group.id} className="group-name">{group.name}</th>)}
          </tr>
        </thead>
        <tbody>
          {machines?.map(machine => <tr key={machine.id}>
            <td>{machine.name}</td>
            {groups?.map(group => <td key={group.id}>
              {prices && <EditablePrice price={findPriceBy(machine.id, group.id)} onSave={handleUpdatePrice} />}
              {packs && <ConfigurePacksButton packsData={filterPacksBy(machine.id, group.id)}
                onError={onError}
                onSuccess={onSuccess}
                groupId={group.id}
                priceableId={machine.id}
                priceableType="Machine" />}
            </td>)}
          </tr>)}
        </tbody>
      </table>
    </div>
  );
};

const MachinesPricingWrapper: React.FC<MachinesPricingProps> = ({ onError, onSuccess }) => {
  return (
    <Loader>
      <MachinesPricing onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('machinesPricing', react2angular(MachinesPricingWrapper, ['onError', 'onSuccess']));
