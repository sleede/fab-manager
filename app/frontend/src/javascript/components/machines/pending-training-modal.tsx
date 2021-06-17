import React from 'react';
import { FabModal } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';

interface PendingTrainingModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  nextReservation: Date,
}

export const PendingTrainingModal: React.FC<PendingTrainingModalProps> = ({ isOpen, toggleModal, nextReservation }) => {
  const { t } = useTranslation('logged');

  /**
   * Return the formatted localized date for the given date
   */
  const formatDate = (date: Date): string => {
    return Intl.DateTimeFormat().format(date);
  }

  return (
    <FabModal title={t('app.logged.pending_training_modal.machine_reservation')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              closeButton={true}>
      <p>{t('app.logged.pending_training_modal.wait_for_validated')}</p>
      <p><HtmlTranslate trKey="training_will_occur_DATE_html" options={{DATE: formatDate(nextReservation)}} /></p>
    </FabModal>
  )
}
