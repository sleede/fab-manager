import React, { Fragment, useState } from 'react';
import { FabButton } from '../base/fab-button';
import { Pencil, Trash } from 'phosphor-react';
import { useTranslation } from 'react-i18next';
import { ProjectSettingOption } from '../../models/project-setting-option';
import { ProjectsSettingOptionForm } from './projects-setting-option-form';

interface ProjectsSettingOptionProps {
  hasDescription?: boolean,
  handleDelete: (id: number) => void,
  handleUpdate: (option: ProjectSettingOption) => void,
  option: ProjectSettingOption
}

/**
 * This component is used by the component ProjectsSetting
 * It provides the display of each option and the update/delete features, all inline.
*/
export const ProjectsSettingOption: React.FC<ProjectsSettingOptionProps> = ({ option, handleDelete, handleUpdate, hasDescription }) => {
  const { t } = useTranslation('admin');

  const [isEditing, setIsEditing] = useState<boolean>(false);

  // If option is in display mode, sets it in editing mode, and vice-versa.
  const toggleIsEditing = () => setIsEditing(prevState => !prevState);

  // Provides the id of the deleted option to parent component, ProjectSetting.
  const deleteOptionLine = () => { handleDelete(option.id); };

  // Provides the updated option to parent component, ProjectSetting.
  const updateOptionLine = (option) => { handleUpdate(option); };

  // UI for displaying an option, when editing mode is off.
  const displayingOptionLine = (
    <tr key={option.id}>
      <td>{option.name}</td>
      <td>{hasDescription && option.description}</td>
      <td className="action-buttons">
        <FabButton className="edit-btn" onClick={toggleIsEditing}>
            <Pencil size={20} aria-label={`${t('app.admin.projects_setting_option.edit')} ${option.name}`}/>
            <span>{t('app.admin.projects_setting_option.edit')}</span>
        </FabButton>
        <FabButton
          className="delete-btn"
          onClick={deleteOptionLine}
          tooltip={`${t('app.admin.projects_setting_option.delete_option')} ${option.name}`}>
          <Trash size={20} aria-label={`${t('app.admin.projects_setting_option.delete_option')} ${option.name}`}/>
        </FabButton>
      </td>
    </tr>
  );

  return (
    <Fragment>
      {!isEditing && displayingOptionLine}
      {isEditing &&
        <ProjectsSettingOptionForm
          option={option}
          handleSave={updateOptionLine}
          handleExit={toggleIsEditing}
          hasDescription={hasDescription}/>}
    </Fragment>
  );
};
