import * as React from 'react';
import { FabModal } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import FormatLib from '../../lib/format';
import { TDateISO } from '../../typings/date-iso';

interface PendingTrainingModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  nextReservation: TDateISO,
}

/**
 * Modal dialog shown if the current user has registered for a training but this training isn't validated
 * when the user tries to book a machine.
 */
export const PendingTrainingModal: React.FC<PendingTrainingModalProps> = ({ isOpen, toggleModal, nextReservation }) => {
  const { t } = useTranslation('logged');

  /**
   * Return the formatted localized date for the given date
   */
  const formatDateTime = (date: TDateISO): string => {
    return t('app.logged.pending_training_modal.DATE_TIME', { DATE: FormatLib.date(date), TIME: FormatLib.time(date) });
  };

  return (
    <FabModal title={t('app.logged.pending_training_modal.machine_reservation')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}>
      <p>{t('app.logged.pending_training_modal.wait_for_validated')}</p>
      <p><HtmlTranslate trKey="app.logged.pending_training_modal.training_will_occur_DATE_html" options={{ DATE: formatDateTime(nextReservation) }} /></p>
    </FabModal>
  );
};
