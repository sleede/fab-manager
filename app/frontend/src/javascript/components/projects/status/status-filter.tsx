import React, { useState, useEffect } from 'react';
import { react2angular } from 'react2angular';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import StatusAPI from '../../../api/status';
import { IApplication } from '../../../models/application';
import { SelectOption } from '../../../models/select';
import { Loader } from '../../base/loader';
import { Status } from '../../../models/status';

declare const Application: IApplication;

interface StatusFilterProps {
  currentStatusIndex: number,
  onFilterChange: (status: Status) => void,
  onError: (message: string) => void
}

/**
 * Implement filtering projects by their status
*/
export const StatusFilter: React.FC<StatusFilterProps> = ({ currentStatusIndex, onError, onFilterChange }) => {
  const { t } = useTranslation('public');
  const defaultValue = { value: null, label: t('app.public.status_filter.all_statuses') };
  const [statusesList, setStatusesList] = useState([]);
  const [currentOption, setCurrentOption] = useState(defaultValue);

  /**
  * From the statusesList (retrieved from API) and a default Value, generates an Array of options conform to react-select
  */
  const buildOptions = (): Array<SelectOption<number|void>> => {
    const apiStatusesList = statusesList.map(status => {
      return { value: status.id, label: status.label };
    });
    return [defaultValue, ...apiStatusesList];
  };

  /**
  * On component mount, asynchronously load the full list of statuses
  */
  useEffect(() => {
    StatusAPI.index()
      .then(setStatusesList)
      .catch(onError);
  }, []);

  // If currentStatusIndex is provided, set currentOption accordingly
  useEffect(() => {
    const selectedOption = statusesList.find((status) => status.id === currentStatusIndex);
    setCurrentOption(selectedOption || defaultValue);
  }, [currentStatusIndex, statusesList]);

  /**
  * Callback triggered when the admin selects a status in the dropdown list
  */
  const handleStatusSelected = (option: SelectOption<number>): void => {
    onFilterChange({ id: option.value, label: option.label });
    setCurrentOption(option);
  };

  const selectStyles = {
    control: (baseStyles, state) => ({
      ...baseStyles,
      boxShadow: state.isFocused ? 'inset 0 1px 1px rgba(0, 0, 0, 0.075), 0 0 8px rgba(253, 222, 63, 0.6);' : 'grey',
      border: state.isFocused ? '1px solid #fdde3f' : '1px solid #c4c4c4',
      color: '#555555',
      '&:hover': {
        borderColor: state.isFocused ? '#fdde3f' : '#c4c4c4'
      }
    }),
    singleValue: (baseStyles) => ({
      ...baseStyles,
      color: '#555555'
    })
  };

  return (
    <div>
      {statusesList.length !== 0 &&
      <Select defaultValue={currentOption}
        value={currentOption}
        id="status"
        className="status-select"
        onChange={handleStatusSelected}
        options={buildOptions()}
        styles={selectStyles}
        aria-label={t('app.public.status_filter.select_status')}/>
      }
    </div>
  );
};

const StatusFilterWrapper: React.FC<StatusFilterProps> = (props) => {
  return (
    <Loader>
      <StatusFilter {...props} />
    </Loader>
  );
};

Application.Components.component('statusFilter', react2angular(StatusFilterWrapper, ['currentStatusIndex', 'onError', 'onFilterChange']));
