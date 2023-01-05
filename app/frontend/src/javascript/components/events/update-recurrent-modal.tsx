import { useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { Event } from '../../models/event';
import { FabModal } from '../base/fab-modal';
import { FabAlert } from '../base/fab-alert';

type EditionMode = 'single' | 'next' | 'all';

interface UpdateRecurrentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  event: Event,
  onConfirmed: (data: Event, mode: EditionMode) => void,
  datesChanged: boolean,
}

/**
 * Ask the user for confimation about the update of only the current event or also its recurrences
 */
export const UpdateRecurrentModal: React.FC<UpdateRecurrentModalProps> = ({ isOpen, toggleModal, event, onConfirmed, datesChanged }) => {
  const { t } = useTranslation('admin');

  const [editMode, setEditMode] = useState<EditionMode>(null);

  /**
   * Callback triggered when the user confirms the update
   */
  const handleConfirmation = () => {
    onConfirmed(event, editMode);
  };

  /**
   * The user cannot confirm unless he chooses an option
   */
  const preventConfirm = () => {
    return !editMode;
  };

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              title={t('app.admin.update_recurrent_modal.title')}
              className="update-recurrent-modal"
              onConfirm={handleConfirmation}
              preventConfirm={preventConfirm()}
              confirmButton={t('app.admin.update_recurrent_modal.confirm', { MODE: editMode })}
              closeButton>
      <p>{t('app.admin.update_recurrent_modal.edit_recurring_event')}</p>
      <label>
        <input name="edit_mode" type="radio" value="single" onClick={() => setEditMode('single')} />
        <span>{t('app.admin.update_recurrent_modal.edit_this_event')}</span>
      </label>
      <label>
        <input name="edit_mode" type="radio" value="next" onClick={() => setEditMode('next')} />
        <span>{t('app.admin.update_recurrent_modal.edit_this_and_next')}</span>
      </label>
      <label>
        <input name="edit_mode" type="radio" value="all" onClick={() => setEditMode('all')} />
        <span>{t('app.admin.update_recurrent_modal.edit_all')}</span>
      </label>
      {datesChanged && editMode !== 'single' && <FabAlert level="warning">
        {t('app.admin.update_recurrent_modal.date_wont_change')}
      </FabAlert>}
    </FabModal>
  );
};
