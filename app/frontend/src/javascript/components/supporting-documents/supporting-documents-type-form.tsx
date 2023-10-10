import * as React from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import { FabInput } from '../base/fab-input';
import { SupportingDocumentType } from '../../models/supporting-document-type';
import { Group } from '../../models/group';
import { SelectOption } from '../../models/select';

interface SupportingDocumentsTypeFormProps {
  groups: Array<Group>,
  supportingDocumentType?: SupportingDocumentType,
  onChange: (field: string, value: string | Array<number>) => void,
}

/**
 * Form to set create/edit supporting documents type
 */
export const SupportingDocumentsTypeForm: React.FC<SupportingDocumentsTypeFormProps> = ({ groups, supportingDocumentType, onChange }) => {
  const { t } = useTranslation('admin');

  /**
   * Convert all groups to the react-select format
   */
  const buildOptions = (): Array<SelectOption<number>> => {
    return groups.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Return the group(s) associated with the current type, formatted to match the react-select format
   */
  const groupsValues = (): Array<SelectOption<number>> => {
    const res = [];
    const groupIds = supportingDocumentType?.group_ids || [];
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
  const handleGroupsChange = (selectedOptions: Array<SelectOption<number>>): void => {
    onChange('group_ids', selectedOptions.map(o => o.value));
  };

  /**
   * Callback triggered when the name has changed.
   */
  const handleNameChange = (value: string): void => {
    onChange('name', value);
  };

  /**
   * to know if select input for groups is display or not
   */
  const displayGroupsSelect = (): boolean => {
    return (supportingDocumentType == null || supportingDocumentType?.document_type === 'User') && (groups.length > 0);
  };

  return (
    <div className="supporting-documents-type-form">
      <div className="info-area">
        {t('app.admin.settings.account.supporting_documents_type_form.type_form_info')}
      </div>
      <form name="supportingDocumentTypeForm">
        {displayGroupsSelect() &&
          <div className="field">
            <Select defaultValue={groupsValues()}
              placeholder={t('app.admin.settings.account.supporting_documents_type_form.select_group')}
              onChange={handleGroupsChange}
              options={buildOptions()}
              isMulti />
          </div>
        }
        <div className="field">
          <FabInput id="supporting_document_type_name"
            icon={<i className="fa fa-edit" />}
            defaultValue={supportingDocumentType?.name || ''}
            placeholder={t('app.admin.settings.account.supporting_documents_type_form.name')}
            onChange={handleNameChange}
            debounce={200}
            required/>
        </div>
      </form>
    </div>
  );
};
