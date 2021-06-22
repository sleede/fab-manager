import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { FabAlert } from '../base/fab-alert';
import { HtmlTranslate } from '../base/html-translate';
import MachineAPI from '../../api/machine';
import GroupAPI from '../../api/group';
import { IFablab } from '../../models/fablab';
import { Machine } from '../../models/machine';
import { Group } from '../../models/group';
import { IApplication } from '../../models/application';
import { EditablePrice } from './editable-price';
import { ConfigurePacksButton } from './configure-packs-button';
import PriceAPI from '../../api/price';
import { Price } from '../../models/price';
import PrepaidPackAPI from '../../api/prepaid-pack';
import { PrepaidPack } from '../../models/prepaid-pack';
import { useImmer } from 'use-immer';

declare var Fablab: IFablab;
declare var Application: IApplication;

interface MachinesPricingProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Interface to set and edit the prices of machines-hours, per group
 */
const MachinesPricing: React.FC<MachinesPricingProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [machines, setMachines] = useState<Array<Machine>>(null);
  const [groups, setGroups] = useState<Array<Group>>(null);
  const [prices, updatePrices] = useImmer<Array<Price>>(null);
  const [packs, setPacks] = useState<Array<PrepaidPack>>(null);

  // retrieve the initial data
  useEffect(() => {
    MachineAPI.index([{ key: 'disabled', value: false }])
      .then(data => setMachines(data))
      .catch(error => onError(error));
    GroupAPI.index({ disabled: false , admins: false })
      .then(data => setGroups(data))
      .catch(error => onError(error));
    PriceAPI.index([{ key: 'priceable_type', value: 'Machine'}, { key: 'plan_id', value: null }])
      .then(data => updatePrices(data))
      .catch(error => onError(error));
    PrepaidPackAPI.index()
      .then(data => setPacks(data))
      .catch(error => onError(error))
  }, []);

  // duration of the example slot
  const EXEMPLE_DURATION = 20;

  /**
   * Return the exemple price, formatted
   */
  const examplePrice = (type: 'hourly_rate' | 'final_price'): string => {
    const hourlyRate = 10;

    if (type === 'hourly_rate') {
      return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).format(hourlyRate);
    }

    const price = (hourlyRate / 60) * EXEMPLE_DURATION;
    return new Intl.NumberFormat(Fablab.intl_locale, { style: 'currency', currency: Fablab.intl_currency }).format(price);
  };

  /**
   * Find the price matching the given criterion
   */
  const findPriceBy = (machineId, groupId): Price => {
    for (const price of prices) {
      if ((price.priceable_id === machineId) && (price.group_id === groupId)) {
        return price;
      }
    }
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
  }

  /**
   * Callback triggered when the user has confirmed to update a price
   */
  const handleUpdatePrice = (price: Price): void => {
    PriceAPI.update(price)
      .then(() => {
        onSuccess(t('app.admin.machines_pricing.price_updated'));
        updatePrice(price);
      })
      .catch(error => onError(error))
  }

  return (
    <div className="machines-pricing">
      <FabAlert level="warning">
        <p><HtmlTranslate trKey="app.admin.machines_pricing.prices_match_machine_hours_rates_html"/></p>
        <p><HtmlTranslate trKey="app.admin.machines_pricing.prices_calculated_on_hourly_rate_html" options={{ DURATION: EXEMPLE_DURATION, RATE: examplePrice('hourly_rate'), PRICE: examplePrice('final_price') }} /></p>
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
            {packs && <ConfigurePacksButton packs={packs} onError={onError} />}
          </td>)}
        </tr>)}
        </tbody>
      </table>
    </div>
  );
}

const MachinesPricingWrapper: React.FC<MachinesPricingProps> = ({ onError, onSuccess }) => {
  return (
    <Loader>
      <MachinesPricing onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
}

Application.Components.component('machinesPricing', react2angular(MachinesPricingWrapper, ['onError', 'onSuccess']));


