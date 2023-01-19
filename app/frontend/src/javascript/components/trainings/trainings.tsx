import * as React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import Select from 'react-select';
import { SelectOption } from '../../models/select';
import { CalendarBlank, PencilSimple, Trash } from 'phosphor-react';

declare const Application: IApplication;

interface TrainingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Admin list of trainings
 */
export const Trainings: React.FC<TrainingsProps> = () => {
  const { t } = useTranslation('admin');

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

  /** Creates filtering options to the react-select format */
  const buildFilterOptions = (): Array<SelectOption<any>> => {
    return [
      { value: 'all', label: t('app.admin.trainings.status_all') },
      { value: 'enabled', label: t('app.admin.trainings.status_enabled') },
      { value: 'disabled', label: t('app.admin.trainings.status_disabled') }
    ];
  };

  /** Handel filter change */
  const onFilterChange = (option: SelectOption<any>) => {
    console.log(option);
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
          <div className='trainings-list-item'>
            <div className='name'>
              <span>{t('app.admin.trainings.name')}</span>
              <p>All you can learn : super training</p>
            </div>

            <div className='machines'>
              <span>{t('app.admin.trainings.associated_machines')}</span>
              <p>Découpeuse laser, Découpeuse vinyle, Shopbot / Grande fraiseuse, Petite Fraiseuse, Imprimante 3D</p>
            </div>

            <div className='cancel'>
              <span>{t('app.admin.trainings.cancellation')}</span>
              <p>5 {t('app.admin.trainings.cancellation_minimum')}<span>|</span>48 {t('app.admin.trainings.cancellation_deadline')}
                {/* si l'item a un réglage spécifique (différent des paramètres généraux) */}
                {true && <span className='override'>{t('app.admin.trainings.override')}</span> }
              </p>
            </div>

            <div className='capacity'>
              <span>{t('app.admin.trainings.capacity')}</span>
              <p>10</p>
            </div>

            <div className='authorisation'>
              <span>{t('app.admin.trainings.authorisation')}</span>
              <p>
                {t('app.admin.trainings.active_true')}
                <span>|</span>{t('app.admin.trainings.period_MONTH', { MONTH: 48 })}
                {/* si l'item a un réglage spécifique (différent des paramètres généraux) */}
                {true && <span className='override'>{t('app.admin.trainings.override')}</span> }
              </p>
            </div>

            <div className='rule'>
              <span>{t('app.admin.trainings.validation_rule')}</span>
              <p>
                {t('app.admin.trainings.active_false')}
                <span>|</span>
                {/* si l'item a un réglage spécifique (différent des paramètres généraux) */}
                {true && <span className='override'>{t('app.admin.trainings.override')}</span> }
              </p>
            </div>

            <div className='actions'>
              <div className='grpBtn'>
                <FabButton className='edit-btn'>
                  <PencilSimple size={20} weight="fill" />
                </FabButton>
                <FabButton className='delete-btn'>
                  <Trash size={20} weight="fill" />
                </FabButton>
              </div>
            </div>
          </div>
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
