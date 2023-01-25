import React, { useState, useRef } from 'react';
import { FabButton } from '../base/fab-button';
import { ProjectSettingOption } from '../../models/project-setting-option';
import { Check, X } from 'phosphor-react';
import { useTranslation } from 'react-i18next';

interface ProjectsSettingOptionFormProps {
  hasDescription?: boolean,
  handleSave: (option: ProjectSettingOption) => void,
  handleExit: () => void,
  option?: ProjectSettingOption
}

/**
* Provides a inline form for a Projects Setting Option
**/
export const ProjectsSettingOptionForm: React.FC<ProjectsSettingOptionFormProps> = ({ option = { name: '', description: '' }, handleSave, handleExit, hasDescription }) => {
  const { t } = useTranslation('admin');

  const enteredOptionName = useRef(null);
  const enteredOptionDescription = useRef(null);

  const [errorMessage, setErrorMessage] = useState<string>('');

  /**
  * Builds up new or updated option based on User input and provides it to parent component.
  * The option property :name should not be blank and triggers an error message for the user.
  **/
  const saveOption = () => {
    if (enteredOptionName.current.value === '') {
      setErrorMessage(t('app.admin.projects_setting_option_form.name_cannot_be_blank'));
      return;
    } else if (hasDescription) {
      handleSave({
        id: option.id,
        name: enteredOptionName.current.value,
        description: enteredOptionDescription.current.value
      });
    } else {
      handleSave({ id: option.id, name: enteredOptionName.current.value });
    }
    setErrorMessage('');
    handleExit();
  };

  return (
    <tr>
      <td>
        <input
          ref={enteredOptionName}
          aria-label={t('app.admin.projects_setting_option_form.name')}
          autoFocus={true}
          defaultValue={option.name}/>
        {errorMessage && <p className="error-msg">{errorMessage}</p>}
      </td>
      <td>
        {hasDescription && <input ref={enteredOptionDescription} defaultValue={option.description}/>}
      </td>
      <td className="action-buttons">
        <FabButton className="save-btn" onClick={saveOption}>
          <Check size={20} weight="bold" aria-label={t('app.admin.projects_setting_option_form.save')} />
        </FabButton>
        <FabButton className="cancel-btn" onClick={handleExit}>
          <X size={20} weight="bold"/>
        </FabButton>
      </td>
    </tr>
  );
};
