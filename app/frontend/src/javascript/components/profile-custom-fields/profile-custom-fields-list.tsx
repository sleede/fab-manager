import React, { useState, useEffect, BaseSyntheticEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import Switch from 'react-switch';
import _ from 'lodash';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ProfileCustomField } from '../../models/profile-custom-field';
import ProfileCustomFieldAPI from '../../api/profile-custom-field';

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
      onSuccess(t('app.admin.settings.compte.organization_profile_custom_field_successfully_updated'));
    }).catch(err => {
      onError(t('app.admin.settings.compte.organization_profile_custom_field_unable_to_update') + err);
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

  const editProfileCustomFieldLabel = (profileCustomField: ProfileCustomField) => {
    return () => {
      setProfileCustomFieldToEdit(_.clone(profileCustomField));
    };
  };

  const onChangeProfileCustomFieldLabel = (e: BaseSyntheticEvent) => {
    const { value } = e.target;
    setProfileCustomFieldToEdit({
      ...profileCustomFieldToEdit,
      label: value
    });
  };

  const saveProfileCustomFieldLabel = () => {
    saveProfileCustomField(profileCustomFieldToEdit);
  };

  const cancelEditProfileCustomFieldLabel = () => {
    setProfileCustomFieldToEdit(null);
  };

  return (
    <table className="table profile-custom-fields-list">
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
                  <button className="btn btn-default edit-profile-custom-field-label m-r-xs pull-right" onClick={editProfileCustomFieldLabel(field)}>
                    <i className="fa fa-edit"></i>
                  </button>
                )}
                {profileCustomFieldToEdit?.id === field.id && (
                  <div>
                    <input className="profile-custom-field-label-input" style={{ width: '80%', height: '38px' }} type="text" value={profileCustomFieldToEdit.label} onChange={onChangeProfileCustomFieldLabel} />
                    <span className="buttons pull-right">
                      <button className="btn btn-success save-profile-custom-field-label m-r-xs" onClick={saveProfileCustomFieldLabel}>
                        <i className="fa fa-check"></i>
                      </button>
                      <button className="btn btn-default delete-profile-custom-field-label m-r-xs" onClick={cancelEditProfileCustomFieldLabel}>
                        <i className="fa fa-ban"></i>
                      </button>
                    </span>
                  </div>
                )}
              </td>
              <td>
                <label htmlFor="profile-custom-field-actived" className="control-label m-r">{t('app.admin.settings.compte.organization_profile_custom_field.actived')}</label>
                <Switch checked={field.actived} id="profile-custom-field-actived" onChange={handleSwitchChanged(field, 'actived')} className="v-middle"></Switch>
              </td>
              <td>
                <label htmlFor="profile-custom-field-required" className="control-label m-r">{t('app.admin.settings.compte.organization_profile_custom_field.required')}</label>
                <Switch checked={field.required} disabled={!field.actived} id="profile-custom-field-required" onChange={handleSwitchChanged(field, 'required')} className="v-middle"></Switch>
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
