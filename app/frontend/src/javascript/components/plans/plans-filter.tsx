import React from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { Group } from '../../models/group';
import { User } from '../../models/user';

interface PlansFilterProps {
  user?: User,
  groups: Array<Group>,
  onGroupSelected: (groupId: number) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

export const PlansFilter: React.FC<PlansFilterProps> = ({ user, groups, onGroupSelected }) => {
  const { t } = useTranslation('public');

  /**
   * Convert all groups to the react-select format
   */
  const buildGroupOptions = (): Array<selectOption> => {
    return groups.filter(g => !g.disabled && g.slug !== 'admins').map(g => {
      return { value: g.id, label: g.name }
    });
  }

  /**
   * Callback triggered when the user select a group in the dropdown list
   */
  const handleGroupSelected = (option: selectOption): void => {
    onGroupSelected(option.value);
  }

  return (
    <div className="plans-filter">
      {!user && <div className="group-filter">
        <label htmlFor="group">{t('app.public.plans_filter.i_am')}</label>
        <Select placeholder={t('app.public.plans_filter.select_group')}
                className="group-select"
                onChange={handleGroupSelected}
                options={buildGroupOptions()}/>
      </div>}
    </div>
  )
}
