import React, { useEffect, useState } from 'react';
import { User } from '../../models/user';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Group } from '../../models/group';
import GroupAPI from '../../api/group';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { useForm } from 'react-hook-form';
import { FormSelect } from '../form/form-select';
import MemberAPI from '../../api/member';

declare const Application: IApplication;

interface ChangeGroupProps {
  user: User,
  onSuccess: (message: string, user: User) => void,
  onError: (message: string) => void,
  allowChange?: boolean,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

export const ChangeGroup: React.FC<ChangeGroupProps> = ({ user, onSuccess, onError, allowChange }) => {
  const { t } = useTranslation('shared');

  const [groups, setGroups] = useState<Array<Group>>([]);
  const [changeRequested, setChangeRequested] = useState<boolean>(false);
  const [operator, setOperator] = useState<User>(null);

  const { handleSubmit, control } = useForm();

  useEffect(() => {
    GroupAPI.index({ disabled: false, admins: false }).then(setGroups).catch(onError);
    MemberAPI.current().then(setOperator).catch(onError);
  }, []);

  useEffect(() => {
    setChangeRequested(false);
  }, [user, allowChange]);

  /**
   * Displays or hide the form to change the group.
   */
  const toggleChangeRequest = () => {
    setChangeRequested(!changeRequested);
  };

  /**
   * Check if the group changing is currently allowed.
   */
  const canChangeGroup = (): boolean => {
    return allowChange;
  };

  /**
   * Convert the provided array of items to the react-select format
   */
  const buildGroupsOptions = (): Array<selectOption> => {
    return groups?.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Callback triggered when the group changing form is submitted.
   */
  const onSubmit = (data: { group_id: number }) => {
    MemberAPI.update({ id: user.id, group_id: data.group_id } as User).then(res => {
      toggleChangeRequest();
      onSuccess(t('app.shared.change_group.success'), res);
    }).catch(onError);
  };

  // do not render the component if no user were provided (we cannot change th group of nobody)
  if (!user) return null;

  return (
    <div className="change-group">
      <h3>{t('app.shared.change_group.title', { OPERATOR: operator?.id === user.id ? 'self' : 'admin' })}</h3>
      {!changeRequested && <div className="display">
        <div className="current-group">
          {groups.find(group => group.id === user.group_id)?.name}
        </div>
        {canChangeGroup() && <FabButton className="request-change-btn" onClick={toggleChangeRequest}>
          {t('app.shared.change_group.change', { OPERATOR: operator?.id === user.id ? 'self' : 'admin' })}
        </FabButton>}
      </div>}
      {changeRequested && <form className="change-group-form" onSubmit={handleSubmit(onSubmit)}>
        <FormSelect options={buildGroupsOptions()} control={control} id="group_id" valueDefault={user.group_id} />
        <div className="actions">
          <FabButton className="cancel-btn" onClick={toggleChangeRequest}>{t('app.shared.change_group.cancel')}</FabButton>
          <FabButton type="submit" className="validate-btn">{t('app.shared.change_group.validate')}</FabButton>
        </div>
      </form>}
    </div>
  );
};

ChangeGroup.defaultProps = {
  allowChange: true
};

const ChangeGroupWrapper: React.FC<ChangeGroupProps> = (props) => {
  return (
    <Loader>
      <ChangeGroup {...props} />
    </Loader>
  );
};

Application.Components.component('changeGroup', react2angular(ChangeGroupWrapper, ['user', 'onSuccess', 'onError', 'allowChange']));
