import { useEffect, useState } from 'react';
import * as React from 'react';
import { FabModal, ModalSize } from '../base/fab-modal';
import { User, UserRole } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import { useForm } from 'react-hook-form';
import MemberAPI from '../../api/member';
import { FormSelect } from '../form/form-select';
import { Group } from '../../models/group';
import GroupAPI from '../../api/group';

declare const Application: IApplication;

interface ChangeRoleModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  user: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

interface RoleFormData {
  role: UserRole,
  groupId?: number
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectRoleOption = { value: UserRole, label: string, isDisabled: boolean };
type selectGroupOption = { value: number, label: string };

/**
 * This modal dialog allows to change the current role of the given user
 */
export const ChangeRoleModal: React.FC<ChangeRoleModalProps> = ({ isOpen, toggleModal, user, onSuccess, onError }) => {
  const { t } = useTranslation('admin');
  const { control, handleSubmit } = useForm<RoleFormData>({ defaultValues: { role: user.role, groupId: user.group_id } });

  const [groups, setGroups] = useState<Array<Group>>([]);

  useEffect(() => {
    GroupAPI.index({ disabled: false }).then(setGroups).catch(onError);
  }, []);

  /**
   * Handle the form submission: update the role on the API
   */
  const onSubmit = (data: RoleFormData) => {
    MemberAPI.updateRole(user, data.role, data.groupId).then(res => {
      onSuccess(
        t(
          'app.admin.change_role_modal.role_changed',
          { OLD: t(`app.admin.change_role_modal.${user.role}`), NEW: t(`app.admin.change_role_modal.${res.role}`) }
        )
      );
      toggleModal();
    }).catch(err => onError(t('app.admin.change_role_modal.error_while_changing_role') + err));
  };

  /**
   * Check if we can change the group of the user
   */
  const canChangeGroup = (): boolean => {
    return !user.subscription;
  };

  /**
   * Return the various available roles for the select input
   */
  const buildRolesOptions = (): Array<selectRoleOption> => {
    return [
      { value: 'admin' as UserRole, label: t('app.admin.change_role_modal.admin'), isDisabled: user.role === 'admin' },
      { value: 'manager' as UserRole, label: t('app.admin.change_role_modal.manager'), isDisabled: user.role === 'manager' },
      { value: 'member' as UserRole, label: t('app.admin.change_role_modal.member'), isDisabled: user.role === 'member' }
    ];
  };

  /**
   * Return the various available groups for the select input
   */
  const buildGroupsOptions = (): Array<selectGroupOption> => {
    return groups.map(group => {
      return { value: group.id, label: group.name };
    });
  };

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              title={t('app.admin.change_role_modal.change_role')}
              width={ModalSize.medium}
              onConfirmSendFormId="user-role-form"
              confirmButton={t('app.admin.change_role_modal.confirm')}
              closeButton>
      <HtmlTranslate trKey={'app.admin.change_role_modal.warning_role_change'} />
      <form onSubmit={handleSubmit(onSubmit)} id="user-role-form">
        <FormSelect options={buildRolesOptions()}
                    control={control}
                    id="role"
                    label={t('app.admin.change_role_modal.new_role')}
                    rules={{ required: true }} />
        <FormSelect options={buildGroupsOptions()}
                    control={control}
                    disabled={!canChangeGroup()}
                    id="groupId"
                    label={t('app.admin.change_role_modal.new_group')}
                    tooltip={t('app.admin.change_role_modal.new_group_help')}
                    rules={{ required: true }} />
      </form>
    </FabModal>
  );
};

const ChangeRoleModalWrapper: React.FC<ChangeRoleModalProps> = (props) => {
  return (
    <Loader>
      <ChangeRoleModal {...props} />
    </Loader>
  );
};

Application.Components.component('changeRoleModal', react2angular(ChangeRoleModalWrapper, ['isOpen', 'toggleModal', 'user', 'onError', 'onSuccess']));
