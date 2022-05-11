import React, { useEffect } from 'react';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { FormInput } from '../form/form-input';
import { useForm, UseFormRegister } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import Authentication from '../../api/authentication';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { PasswordInput } from './password-input';
import { FormState } from 'react-hook-form/dist/types/form';
import MemberAPI from '../../api/member';

interface ChangePasswordProp<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  onError: (message: string) => void,
  currentFormPassword: string,
  formState: FormState<TFieldValues>,
}

/**
 * This component shows a button that trigger a modal dialog to verify the user's current password.
 * If the user's current password is correct, the modal dialog is closed and the button is replaced by a form to set the new password.
 */
export const ChangePassword = <TFieldValues extends FieldValues>({ register, onError, currentFormPassword, formState }: ChangePasswordProp<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [isModalOpen, setIsModalOpen] = React.useState<boolean>(false);
  const [isConfirmedPassword, setIsConfirmedPassword] = React.useState<boolean>(false);
  const [isPrivileged, setIsPrivileged] = React.useState<boolean>(false);

  const { handleSubmit, register: passwordRegister } = useForm<{ password: string }>();

  useEffect(() => {
    MemberAPI.current().then(user => {
      setIsPrivileged(user.role === 'admin' || user.role === 'manager');
    }).catch(error => onError(error));
  }, []);

  /**
   * Opens/closes the dialog asking to confirm the current password before changing it.
   */
  const toggleConfirmationModal = () => {
    setIsModalOpen(!isModalOpen);
  };

  /**
   * Callback triggered when the user clicks on the "change my password" button
   */
  const handleChangePasswordRequested = () => {
    if (isPrivileged) {
      setIsConfirmedPassword(true);
    } else {
      toggleConfirmationModal();
    }
  };

  /**
   * Callback triggered when the user confirms his current password.
   */
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    return handleSubmit((data: { password: string }) => {
      Authentication.verifyPassword(data.password).then(res => {
        if (res) {
          setIsConfirmedPassword(true);
          toggleConfirmationModal();
        } else {
          onError(t('app.shared.change_password.wrong_password'));
        }
      }).catch(err => {
        onError(err);
      });
    })(event);
  };

  return (
    <div className="change-password">
      {!isConfirmedPassword && <FabButton onClick={() => handleChangePasswordRequested()}>
        {t('app.shared.change_password.change_my_password')}
      </FabButton>}
      {isConfirmedPassword && <div className="password-fields">
        <PasswordInput register={register} currentFormPassword={currentFormPassword} formState={formState} />
      </div>}
      <FabModal isOpen={isModalOpen} toggleModal={toggleConfirmationModal} title={t('app.shared.change_password.change_my_password')} closeButton>
        <form onSubmit={onSubmit}>
          <FormInput id="password"
                     type="password"
                     register={passwordRegister}
                     rules={{ required: true }}
                     label={t('app.shared.change_password.confirm_current')} />
          <FabButton type="submit">
            {t('app.shared.change_password.confirm')}
          </FabButton>
        </form>
      </FabModal>
    </div>
  );
};
