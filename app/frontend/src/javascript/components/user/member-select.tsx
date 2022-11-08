import React, { useState, useEffect } from 'react';
import AsyncSelect from 'react-select/async';
import { useTranslation } from 'react-i18next';
import MemberAPI from '../../api/member';
import { User } from '../../models/user';
import { SelectOption } from '../../models/select';

interface MemberSelectProps {
  defaultUser?: User,
  value?: User,
  onSelected?: (user: { id: number, name: string }) => void,
  noHeader?: boolean,
  hasError?: boolean
}

/**
 * This component renders the member select for manager.
 */
export const MemberSelect: React.FC<MemberSelectProps> = ({ defaultUser, value, onSelected, noHeader, hasError }) => {
  const { t } = useTranslation('public');
  const [option, setOption] = useState<SelectOption<number>>();

  useEffect(() => {
    if (defaultUser) {
      setOption({ value: defaultUser.id, label: defaultUser.name });
    }
  }, []);

  useEffect(() => {
    if (!defaultUser && option) {
      onSelected({ id: option.value, name: option.label });
    }
  }, [defaultUser]);

  useEffect(() => {
    if (value && value?.id !== option?.value) {
      setOption({ value: value.id, label: value.name });
    }
    if (!value) {
      setOption(null);
    }
  }, [value]);

  /**
   * search members by name
   */
  const loadMembers = async (inputValue: string): Promise<Array<SelectOption<number>>> => {
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
  const onChange = (v: SelectOption<number>) => {
    setOption(v);
    onSelected({ id: v.value, name: v.label });
  };

  return (
    <div className={`member-select ${hasError ? 'error' : ''}`}>
      {!noHeader &&
        <div className="member-select-header">
          <h3 className="member-select-title">{t('app.public.member_select.select_a_member')}</h3>
        </div>
      }
      <AsyncSelect placeholder={t('app.public.member_select.start_typing')}
                   className="select-input"
                   cacheOptions
                   loadOptions={loadMembers}
                   defaultOptions
                   onChange={onChange}
                   value={option}
      />
    </div>
  );
};

MemberSelect.defaultProps = {
  hasError: false
};
