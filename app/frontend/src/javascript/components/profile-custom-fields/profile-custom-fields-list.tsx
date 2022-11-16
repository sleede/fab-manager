import { useState, useEffect, BaseSyntheticEvent } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import Switch from 'react-switch';
import _ from 'lodash';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ProfileCustomField } from '../../models/profile-custom-field';
import ProfileCustomFieldAPI from '../../api/profile-custom-field';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface ProfileCustomFieldsListProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of all profile custom fields
 */
export const ProfileCustomFieldsList: React.FC<ProfileCustomFieldsListProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [profileCustomFields, setProfileCustomFields] = useState<Array<ProfileCustomField>>([]);
  const [profileCustomFieldToEdit, setProfileCustomFieldToEdit] = useState<ProfileCustomField>(null);

  // get profile custom fields
  useEffect(() => {
    ProfileCustomFieldAPI.index().then(pData => {
      setProfileCustomFields(pData);
    });
  }, []);

  /**
   * Save the new state of the given custom field to the API
   */
  const saveProfileCustomField = (profileCustomField: ProfileCustomField) => {
    ProfileCustomFieldAPI.update(profileCustomField).then(data => {
      const newFields = profileCustomFields.map(f => {
        if (f.id === data.id) {
          return data;
        }
        return f;
      });
      setProfileCustomFields(newFields);
      if (profileCustomFieldToEdit) {
        setProfileCustomFieldToEdit(null);
      }
      onSuccess(t('app.admin.settings.account.profile_custom_fields_list.field_successfully_updated'));
    }).catch(err => {
      onError(t('app.admin.settings.account.profile_custom_fields_list.unable_to_update') + err);
    });
  };

  /**
   * Callback triggered when the 'switch' is changed.
   */
  const handleSwitchChanged = (profileCustomField: ProfileCustomField, field: string) => {
    return (value: boolean) => {
      const _profileCustomField = _.clone(profileCustomField);
      _profileCustomField[field] = value;
      if (field === 'actived' && !value) {
        _profileCustomField.required = false;
      }
      saveProfileCustomField(_profileCustomField);
    };
  };

  /**
   * Callback triggered when the user clicks on the 'edit field' button.
   * Opens the edition form for the given custom field
   */
  const editProfileCustomFieldLabel = (profileCustomField: ProfileCustomField) => {
    return () => {
      setProfileCustomFieldToEdit(_.clone(profileCustomField));
    };
  };

  /**
   * Callback triggered when the input "label" is changed: updates the according state
   */
  const onChangeProfileCustomFieldLabel = (e: BaseSyntheticEvent) => {
    const { value } = e.target;
    setProfileCustomFieldToEdit({
      ...profileCustomFieldToEdit,
      label: value
    });
  };

  /**
   * Save the currently edited custom field
   */
  const saveProfileCustomFieldLabel = () => {
    saveProfileCustomField(profileCustomFieldToEdit);
  };

  /**
   * Closes the edition form for the currently edited custom field
   */
  const cancelEditProfileCustomFieldLabel = () => {
    setProfileCustomFieldToEdit(null);
  };

  return (
    <table className="profile-custom-fields-list">
      <thead>
        <tr>
          <th style={{ width: '50%' }}></th>
          <th style={{ width: '25%' }}></th>
          <th style={{ width: '25%' }}></th>
        </tr>
      </thead>
      <tbody>
        {profileCustomFields.map(field => {
          return (
            <tr key={field.id}>
              <td>
                {profileCustomFieldToEdit?.id !== field.id && field.label}
                {profileCustomFieldToEdit?.id !== field.id && (
                  <FabButton className="edit-field-button" onClick={editProfileCustomFieldLabel(field)}>
                    <i className="fa fa-edit"></i>
                  </FabButton>
                )}
                {profileCustomFieldToEdit?.id === field.id && (
                  <div>
                    <input className="edit-field-label-input"
                      type="text" value={profileCustomFieldToEdit.label}
                      onChange={onChangeProfileCustomFieldLabel} />
                    <span className="buttons">
                      <FabButton className="save-field-label" onClick={saveProfileCustomFieldLabel}>
                        <i className="fa fa-check"></i>
                      </FabButton>
                      <FabButton className="cancel-field-edition" onClick={cancelEditProfileCustomFieldLabel}>
                        <i className="fa fa-ban"></i>
                      </FabButton>
                    </span>
                  </div>
                )}
              </td>
              <td className="activated">
                <label htmlFor="profile-custom-field-actived">
                  {t('app.admin.settings.account.profile_custom_fields_list.actived')}
                </label>
                <Switch checked={field.actived}
                  id="profile-custom-field-actived"
                  onChange={handleSwitchChanged(field, 'actived')}
                  className="switch"></Switch>
              </td>
              <td className="required">
                <label htmlFor="profile-custom-field-required">
                  {t('app.admin.settings.account.profile_custom_fields_list.required')}
                </label>
                <Switch checked={field.required}
                  disabled={!field.actived}
                  id="profile-custom-field-required"
                  onChange={handleSwitchChanged(field, 'required')}
                  className="switch"></Switch>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

const ProfileCustomFieldsListWrapper: React.FC<ProfileCustomFieldsListProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <ProfileCustomFieldsList onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('profileCustomFieldsList', react2angular(ProfileCustomFieldsListWrapper, ['onSuccess', 'onError']));
