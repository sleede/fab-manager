import React, { useState } from 'react';
import { FabButton } from '../base/fab-button';
import { ProjectsSettingOption } from './projects-setting-option';
import { useTranslation } from 'react-i18next';
import { ProjectSettingOption } from '../../models/project-setting-option';
import { ProjectsSettingOptionForm } from './projects-setting-option-form';

interface ProjectsSettingProps {
  hasDescription?: boolean,
  handleAdd: (option: ProjectSettingOption) => void,
  handleDelete: (id: number) => void,
  handleUpdate: (option: ProjectSettingOption) => void,
  optionType: string,
  options: ProjectSettingOption[]
}

/**
 * This component is used in Projects Settings (admin part)
 * It provides add / update / delete features for any setting of a project (status, themes, licences...)
 * If a Setting has a description property, this component should be called with the prop hasDescription={true}
*/
export const ProjectsSetting: React.FC<ProjectsSettingProps> = ({ hasDescription = false, handleAdd, handleUpdate, handleDelete, options, optionType }) => {
  const { t } = useTranslation('admin');
  const [isAdding, setIsAdding] = useState<boolean>(false);

  // Shows form to add an option if it's not already here. Else, removes it.
  const toggleIsAdding = () => setIsAdding((prevState) => !prevState);

  // Pass on the newly created option to parent component.
  const addOption = (option) => { handleAdd(option); };

  return (
    <div className="projects-setting">
      <FabButton
        className="add-btn"
        onClick={toggleIsAdding}
        type="button">
        {`${t('app.admin.projects_setting.add')} a ${optionType}`}
      </FabButton>
      <table>
        <thead>
          <tr>
            <th style={{ width: hasDescription ? '30%' : '80%' }}>{t('app.admin.projects_setting.name')}</th>
            {hasDescription &&
              <th style={{ width: '50%' }} aria-hidden='false'>{t('app.admin.projects_setting.description')}</th>
            }
            {!hasDescription &&
              <th style={{ width: '0%' }} aria-hidden='true'></th>
            }
            <th style={{ width: '20%' }} aria-label={t('app.admin.projects_setting.actions_controls')}></th>
          </tr>
          </thead>
          <tbody>
          {options.map((option) => {
            return (
              <ProjectsSettingOption
                key={option.id}
                option={option}
                hasDescription={hasDescription}
                handleDelete={handleDelete}
                handleUpdate={handleUpdate}/>
            );
          })}
          {isAdding &&
          <ProjectsSettingOptionForm
            hasDescription={hasDescription}
            handleSave={addOption}
            handleExit={toggleIsAdding}/>
          }
          </tbody>
      </table>
    </div>
  );
};
