import React from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import { FabInput } from '../base/fab-input';
import { ProofOfIdentityType } from '../../models/proof-of-identity-type';
import { Group } from '../../models/group';

interface ProofOfIdentityTypeFormProps {
  groups: Array<Group>,
  proofOfIdentityType?: ProofOfIdentityType,
  onChange: (field: string, value: string | Array<number>) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * Form to set the stripe's public and private keys
 */
export const ProofOfIdentityTypeForm: React.FC<ProofOfIdentityTypeFormProps> = ({ groups, proofOfIdentityType, onChange }) => {
  const { t } = useTranslation('admin');

  /**
   * Convert all themes to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return groups.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Return the current groups(s), formatted to match the react-select format
   */
  const groupsValues = (): Array<selectOption> => {
    const res = [];
    const groupIds = proofOfIdentityType?.group_ids || [];
    if (groupIds.length > 0) {
      groups.forEach(t => {
        if (groupIds.indexOf(t.id) > -1) {
          res.push({ value: t.id, label: t.name });
        }
      });
    }
    return res;
  };

  /**
   * Callback triggered when the selection of group has changed.
   */
  const handleGroupsChange = (selectedOptions: Array<selectOption>): void => {
    onChange('group_ids', selectedOptions.map(o => o.value));
  };

  /**
   * Callback triggered when the name has changed.
   */
  const handleNameChange = (value: string): void => {
    onChange('name', value);
  };

  return (
    <div className="proof-of-identity-type-form">
      <div className="proof-of-identity-type-form-info">
        {t('app.admin.settings.compte.proof_of_identity_type_form_info')}
      </div>
      <form name="proofOfIdentityTypeForm">
        <div className="proof-of-identity-type-select m-t">
          <Select defaultValue={groupsValues()}
            placeholder={t('app.admin.settings.compte.proof_of_identity_type_select_group')}
            onChange={handleGroupsChange}
            options={buildOptions()}
            isMulti />
        </div>
        <div className="proof-of-identity-type-input m-t">
          <FabInput id="proof_of_identity_type_name"
            icon={<i className="fa fa-edit" />}
            defaultValue={proofOfIdentityType?.name || ''}
            placeholder={t('app.admin.settings.compte.proof_of_identity_type_input_name')}
            onChange={handleNameChange}
            debounce={200}
            required/>
        </div>
      </form>
    </div>
  );
};
