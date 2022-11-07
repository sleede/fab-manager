import React, { useEffect, useState } from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { Group } from '../../models/group';
import { User } from '../../models/user';
import PlanAPI from '../../api/plan';
import { PlansDuration } from '../../models/plan';
import { SelectOption } from '../../models/select';

interface PlansFilterProps {
  user?: User,
  groups: Array<Group>,
  onGroupSelected: (groupId: number) => void,
  onError: (message: string) => void,
  onDurationSelected: (plansIds: Array<number>) => void,
}

/**
 * Allows filtering on plans list
 */
export const PlansFilter: React.FC<PlansFilterProps> = ({ user, groups, onGroupSelected, onError, onDurationSelected }) => {
  const { t } = useTranslation('public');

  const [durations, setDurations] = useState<Array<PlansDuration>>(null);

  // get the plans durations on component load
  useEffect(() => {
    PlanAPI.durations().then(data => {
      setDurations(data);
    }).catch(error => onError(error));
  }, []);

  /**
   * Convert all groups to the react-select format
   */
  const buildGroupOptions = (): Array<SelectOption<number>> => {
    return groups.filter(g => !g.disabled).map(g => {
      return { value: g.id, label: g.name };
    });
  };

  /**
   * Convert all durations to the react-select format
   */
  const buildDurationOptions = (): Array<SelectOption<number>> => {
    const options = durations.map((d, index) => {
      return { value: index, label: d.name };
    });
    options.unshift({ value: null, label: t('app.public.plans_filter.all_durations') });
    return options;
  };

  /**
   * Callback triggered when the user selects a group in the dropdown list
   */
  const handleGroupSelected = (option: SelectOption<number>): void => {
    onGroupSelected(option.value);
  };

  /**
   * Callback triggered when the user selects a duration in the dropdown list
   */
  const handleDurationSelected = (option: SelectOption<number>): void => {
    onDurationSelected(durations[option.value]?.plans_ids);
  };

  return (
    <div className="plans-filter">
      {!user && <div className="group-filter">
        <label htmlFor="group">{t('app.public.plans_filter.i_am')}</label>
        <Select placeholder={t('app.public.plans_filter.select_group')}
          id="group"
          className="group-select"
          onChange={handleGroupSelected}
          options={buildGroupOptions()}/>
      </div>}
      {durations && <div className="duration-filter">
        <label htmlFor="duration">{t('app.public.plans_filter.i_want_duration')}</label>
        <Select placeholder={t('app.public.plans_filter.select_duration')}
          id="duration"
          className="duration-select"
          onChange={handleDurationSelected}
          options={buildDurationOptions()}/>
      </div>}
    </div>
  );
};
