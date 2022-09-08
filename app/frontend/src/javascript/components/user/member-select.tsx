import React, { useState, useEffect } from 'react';
import AsyncSelect from 'react-select/async';
import { useTranslation } from 'react-i18next';
import MemberAPI from '../../api/member';
import { User } from '../../models/user';

interface MemberSelectProps {
  defaultUser?: User,
  onSelected?: (userId: number) => void,
  noHeader?: boolean
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * This component renders the member select for manager.
 */
export const MemberSelect: React.FC<MemberSelectProps> = ({ defaultUser, onSelected, noHeader }) => {
  const { t } = useTranslation('public');
  const [value, setValue] = useState<selectOption>();

  useEffect(() => {
    if (defaultUser) {
      setValue({ value: defaultUser.id, label: defaultUser.name });
    }
  }, []);

  useEffect(() => {
    if (!defaultUser && value) {
      onSelected(value.value);
    }
  }, [defaultUser]);

  /**
   * search members by name
   */
  const loadMembers = async (inputValue: string): Promise<Array<selectOption>> => {
    if (!inputValue) {
      return [];
    }
    const data = await MemberAPI.search(inputValue);
    return data.map(u => {
      return { value: u.id, label: u.name };
    });
  };

  /**
   * callback for handle select changed
   */
  const onChange = (v: selectOption) => {
    setValue(v);
    onSelected(v.value);
  };

  return (
    <div className="member-select">
      {!noHeader &&
        <div className="member-select-header">
          <h3 className="member-select-title">{t('app.public.member_select.select_a_member')}</h3>
        </div>
      }
      <AsyncSelect placeholder={t('app.public.member_select.start_typing')}
                   cacheOptions
                   loadOptions={loadMembers}
                   defaultOptions
                   onChange={onChange}
                   value={value}
      />
    </div>
  );
};
