import * as React from 'react';
import { FabModal } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { SubmitHandler, useForm } from 'react-hook-form';
import { Partner } from '../../models/plan';
import UserAPI from '../../api/user';
import { User } from '../../models/user';
import { FormInput } from '../form/form-input';

interface PartnerModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onError: (message: string) => void,
  onPartnerCreated: (partner: User) => void,
}

/**
 * Modal dialog to add o new user with role 'partner'
 */
export const PartnerModal: React.FC<PartnerModalProps> = ({ isOpen, toggleModal, onError, onPartnerCreated }) => {
  const { t } = useTranslation('admin');
  const { handleSubmit, register, formState } = useForm<Partner>();

  /**
   * Callback triggered when the user validates the partner form: create the partner on the API
   */
  const onSubmit: SubmitHandler<Partner> = (data: Partner) => {
    UserAPI.create(data).then(onPartnerCreated).catch(onError);
  };

  return (
    <FabModal isOpen={isOpen}
              title={t('app.admin.partner_modal.title')}
              toggleModal={toggleModal}
              confirmButton={t('app.admin.partner_modal.create_partner')}
              onConfirmSendFormId="partner-form"
              closeButton>
      <form onSubmit={handleSubmit(onSubmit)} id="partner-form">
        <FormInput register={register}
                   label={t('app.admin.partner_modal.first_name')}
                   id="first_name"
                   rules={{ required: true }}
                   formState={formState} />
        <FormInput register={register}
                   label={t('app.admin.partner_modal.surname')}
                   id="last_name"
                   rules={{ required: true }}
                   formState={formState} />
        <FormInput register={register}
                   label={t('app.admin.partner_modal.email')}
                   id="email"
                   rules={{ required: true }}
                   formState={formState} />
      </form>
    </FabModal>
  );
};
