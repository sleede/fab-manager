import * as React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import Select from 'react-select';
import { SelectOption } from '../../models/select';
import { CalendarBlank, PencilSimple } from 'phosphor-react';
import { useEffect, useState } from 'react';
import type { Training } from '../../models/training';
import type { Machine } from '../../models/machine';
import TrainingAPI from '../../api/training';
import MachineAPI from '../../api/machine';
import { DestroyButton } from '../base/destroy-button';

declare const Application: IApplication;

interface TrainingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Admin list of trainings
 */
export const Trainings: React.FC<TrainingsProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [trainings, setTrainings] = useState<Array<Training>>([]);
  const [machines, setMachines] = useState<Array<Machine>>([]);
  const [filter, setFilter] = useState<boolean>(null);

  // Styles the React-select component
  const customStyles = {
    control: base => ({
      ...base,
      width: '20ch',
      border: 'none',
      backgroundColor: 'transparent'
    }),
    indicatorSeparator: () => ({
      display: 'none'
    })
  };

  useEffect(() => {
    MachineAPI.index({ disabled: false })
      .then(setMachines)
      .catch(onError);
  }, []);

  useEffect(() => {
    TrainingAPI.index(typeof filter === 'boolean' ? { disabled: filter } : {})
      .then(setTrainings)
      .catch(onError);
  }, [filter]);

  /** Creates filtering options to the react-select format */
  const buildFilterOptions = (): Array<SelectOption<boolean>> => {
    return [
      { value: null, label: t('app.admin.trainings.status_all') },
      { value: false, label: t('app.admin.trainings.status_enabled') },
      { value: true, label: t('app.admin.trainings.status_disabled') }
    ];
  };

  /** Handel filter change */
  const onFilterChange = (option: SelectOption<boolean>) => {
    setFilter(option.value);
  };

  /**
   * List of machines names for teh given ids
   */
  const machinesNames = (ids: Array<number>): string => {
    return machines.filter(m => ids.includes(m.id)).map(m => m.name).join(', ');
  };

  /**
   *
   * Check if the given training has associated non-disabled machines
   */
  const hasMachines = (training: Training): boolean => {
    const activesMachines = machines.map(m => m.id);
    return training.machine_ids.filter(id => activesMachines.includes(id)).length > 0;
  };

  /**
   * Redirect the user to the given training edition page
   */
  const toTrainingEdit = (training: Training): void => {
    window.location.href = `/#!/admin/trainings/${training.id}/edit`;
  };

  /** Link to calendar page */
  const toCalendar = (): void => {
    window.location.href = '/#!/admin/calendar';
  };

  /** Link to new training page */
  const newTraining = (): void => {
    window.location.href = '/#!/admin/trainings/new';
  };

  return (
    <div className='trainings'>
      <header>
        <h2>{t('app.admin.trainings.all_trainings')}</h2>
        <div className='grpBtn'>
          <FabButton onClick={toCalendar}><CalendarBlank size={20} /></FabButton>
          <FabButton className="main-action-btn" onClick={newTraining}>{t('app.admin.trainings.add_a_new_training')}</FabButton>
        </div>
      </header>

      <div className="trainings-content">
        <div className='display'>
          <div className='filter'>
            <p>{t('app.admin.trainings.filter_status')}</p>
            <Select
              options={buildFilterOptions()}
              onChange={evt => onFilterChange(evt)}
              styles={customStyles} />
          </div>
        </div>

        <div className='trainings-list'>
          {/* map
            ajouter la classe .is-override si l'item a au moins un réglage spécifique (différent des paramètres généraux)
          */}
          {trainings.map(training => (
            <div className='trainings-list-item' key={training.id}>
              <div className='name'>
                <span>{t('app.admin.trainings.name')}</span>
                <p>{training.name}</p>
              </div>

              {(hasMachines(training) && <div className='machines'>
                <span>{t('app.admin.trainings.associated_machines')}</span>
                <p>{machinesNames(training.machine_ids)}</p>
              </div>) || <div/>}

              <div className='cancel'>
                <span>{t('app.admin.trainings.cancellation')}</span>
                <p>5 {t('app.admin.trainings.cancellation_minimum')}<span>|</span>48 {t('app.admin.trainings.cancellation_deadline')}
                </p>
              </div>

              <div className='capacity'>
                <span>{t('app.admin.trainings.capacity')}</span>
                <p>{training.nb_total_places}</p>
              </div>

              <div className='authorisation'>
                <span>{t('app.admin.trainings.authorisation')}</span>
                <p>
                  {t('app.admin.trainings.active_true')}
                  <span>|</span>{t('app.admin.trainings.period_MONTH', { MONTH: 48 })}
                </p>
              </div>

              <div className='rule'>
                <span>{t('app.admin.trainings.validation_rule')}</span>
                <p>
                  {t('app.admin.trainings.active_false')}
                </p>
              </div>

              <div className='actions'>
                <div className='grpBtn'>
                  <FabButton className='edit-btn' onClick={() => toTrainingEdit(training)}>
                    <PencilSimple size={20} weight="fill" />
                  </FabButton>
                  <DestroyButton onSuccess={onSuccess}
                                 className="delete-btn"
                                 onError={onError}
                                 itemId={training.id}
                                 itemType={t('app.admin.trainings.training')}
                                 apiDestroy={TrainingAPI.destroy} />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const TrainingsWrapper: React.FC<TrainingsProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <Trainings {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('trainings', react2angular(TrainingsWrapper, ['onError', 'onSuccess']));
