import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useFieldArray, UseFormRegister } from 'react-hook-form';
import { Control, FormState, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { Plan } from '../../models/plan';
import { FormInput } from '../form/form-input';
import { Machine } from '../../models/machine';
import { Space } from '../../models/space';
import SettingAPI from '../../api/setting';
import { SettingName } from '../../models/setting';
import MachineAPI from '../../api/machine';
import SpaceAPI from '../../api/space';
import { Price } from '../../models/price';
import FormatLib from '../../lib/format';
import { FabTabs } from '../base/fab-tabs';
import PlanAPI from '../../api/plan';
import { FormSelect } from '../form/form-select';
import { SelectOption } from '../../models/select';

interface PlanPricingFormProps<TContext extends object> {
  register: UseFormRegister<Plan>,
  control: Control<Plan, TContext>
  formState: FormState<Plan>,
  setValue: UseFormSetValue<Plan>,
  onError: (message: string) => void,
}

/**
 * Sub-form to define prices for machines and spaces, for the current plan
 */
export const PlanPricingForm = <TContext extends object>({ register, control, formState, setValue, onError }: PlanPricingFormProps<TContext>) => {
  const { t } = useTranslation('admin');
  const { fields } = useFieldArray({ control, name: 'prices_attributes' });

  const [machines, setMachines] = useState<Array<Machine>>(null);
  const [spaces, setSpaces] = useState<Array<Space>>(null);
  const [settings, setSettings] = useState<Map<SettingName, string>>(null);
  const [plans, setPlans] = useState<Array<SelectOption<number>>>(null);

  useEffect(() => {
    SettingAPI.query(['spaces_module', 'machines_module']).then(setSettings).catch(onError);
    PlanAPI.index()
      .then(res => setPlans(res.map(p => { return { value: p.id, label: p.name }; })))
      .catch(onError);
  }, []);

  useEffect(() => {
    if (settings?.get('machines_module') === 'true') {
      MachineAPI.index().then(setMachines).catch(onError);
    }
    if (settings?.get('spaces_module') === 'true') {
      SpaceAPI.index().then(setSpaces).catch(onError);
    }
  }, [settings]);

  /**
   * Copy prices from the selected plan
   */
  const handleCopyPrices = (planId: number) => {
    PlanAPI.get(planId).then(parent => {
      parent.prices_attributes.forEach(price => {
        const index = fields.findIndex(p => p.priceable_type === price.priceable_type && p.priceable_id === price.priceable_id);
        setValue(`prices_attributes.${index}.amount`, price.amount);
      });
    }).catch(onError);
  };

  /**
   * Render the form element for the given price
   */
  const renderPriceElement = (price: Price, index: number) => {
    const item: Space | Machine = (price.priceable_type === 'Machine' && machines?.find(m => m.id === price.priceable_id)) ||
                                  (price.priceable_type === 'Space' && spaces?.find(s => s.id === price.priceable_id));
    if (!item?.disabled) {
      return (
        <div key={index}>
          <FormInput register={register}
                     id={`prices_attributes.${index}.id`}
                     formState={formState}
                     type="hidden" />
          <FormInput register={register}
                     label={item?.name}
                     id={`prices_attributes.${index}.amount`}
                     rules={{ required: true, min: 0 }}
                     step={0.01}
                     formState={formState}
                     type="number"
                     addOn={FormatLib.currencySymbol()} />
        </div>
      );
    }
  };

  return (
    <>
      <h4>{t('app.admin.plan_pricing_form.prices')}</h4>
      {plans && <FormSelect options={plans}
                            label={t('app.admin.plan_pricing_form.copy_prices_from')}
                            tooltip={t('app.admin.plan_pricing_form.copy_prices_from_help')}
                            control={control}
                            onChange={handleCopyPrices}
                            id="parent_plan_id" />}
      {<FabTabs tabs={[
        machines && {
          id: 'machines',
          title: t('app.admin.plan_pricing_form.machines'),
          content: fields.filter(p => p.priceable_type === 'Machine').map((price, index) =>
            renderPriceElement(price, index)
          )
        },
        spaces && {
          id: 'spaces',
          title: t('app.admin.plan_pricing_form.spaces'),
          content: fields.filter(p => p.priceable_type === 'Space').map((price, index) =>
            renderPriceElement(price, index)
          )
        }
      ]} />}
    </>
  );
};
