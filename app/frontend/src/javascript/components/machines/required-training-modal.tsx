import React, { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { HtmlTranslate } from '../base/html-translate';
import { Machine } from '../../models/machine';
import { User } from '../../models/user';
import { Avatar } from '../user/avatar';
import { FabButton } from '../base/fab-button';

interface RequiredTrainingModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  user?: User,
  machine?: Machine,
  onEnrollRequested: (trainingId: number) => void,
}
/**
 * Modal dialog shown if the current user does not have the required training to book the given machine
 */
export const RequiredTrainingModal: React.FC<RequiredTrainingModalProps> = ({ isOpen, toggleModal, user, machine, onEnrollRequested }) => {
  const { t } = useTranslation('logged');

  /**
   * Properly format the list of allowed trainings
   */
  const formatTrainings = (): string => {
    if (!machine) return '';

    return machine.trainings.map(t => t.name).join(t('app.logged.required_training_modal.training_or_training_html'));
  };

  /**
   * Callback triggered when the user has clicked on the "enroll" button
   */
  const handleEnroll = (): void => {
    onEnrollRequested(machine.trainings[0].id);
  };

  /**
   * Custom header of the dialog: we display the username and avatar
   */
  const header = (): ReactNode => {
    return (
      <div className="user-info">
        <Avatar user={user} />
        <span className="user-name">{user?.name}</span>
      </div>
    );
  };

  /**
   * Custom footer of the dialog: we display a user-friendly message to close the dialog
   */
  const footer = (): ReactNode => {
    return (
      <div className="not-now">
        <p>{t('app.logged.required_training_modal.no_enroll_for_now')}</p>
        <a onClick={toggleModal}>{t('app.logged.required_training_modal.close')}</a>
      </div>
    );
  };

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      className="required-training-modal"
      closeButton={false}
      customHeader={header()}
      customFooter={footer()}>
      <div className="training-info">
        <p>
          <HtmlTranslate trKey={'app.logged.required_training_modal.to_book_MACHINE_requires_TRAINING_html'}
            options={{ MACHINE: machine?.name, TRAINING: formatTrainings() }} />
        </p>
        <div className="enroll-container">
          <FabButton onClick={handleEnroll}>{t('app.logged.required_training_modal.enroll_now')}</FabButton>
        </div>
      </div>
    </FabModal>
  );
};
