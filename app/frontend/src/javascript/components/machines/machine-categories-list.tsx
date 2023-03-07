import React, { useEffect, useState } from 'react';
import { MachineCategory } from '../../models/machine-category';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineCategoryAPI from '../../api/machine-category';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { MachineCategoryModal } from './machine-category-modal';
import { EditDestroyButtons } from '../base/edit-destroy-buttons';

declare const Application: IApplication;

interface MachineCategoriesListProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * This component shows a list of all machines and allows filtering on that list.
 */
export const MachineCategoriesList: React.FC<MachineCategoriesListProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  // shown machine categories
  const [machineCategories, setMachineCategories] = useState<Array<MachineCategory>>([]);
  // creation/edition modal
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);
  // currently added/edited category
  const [machineCategory, setMachineCategory] = useState<MachineCategory>(null);

  // retrieve the full list of machine categories on component mount
  useEffect(() => {
    MachineCategoryAPI.index()
      .then(setMachineCategories)
      .catch(onError);
  }, []);

  /**
   * Toggle the modal dialog to create/edit a machine category
   */
  const toggleCreateAndEditModal = (): void => {
    setModalIsOpen(!modalIsOpen);
  };

  /**
   * Callback triggred when the current machine category was successfully saved
   */
  const onSaveTypeSuccess = (message: string): void => {
    setModalIsOpen(false);
    MachineCategoryAPI.index().then(data => {
      setMachineCategories(data);
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load machine categories' + error);
    });
  };

  /**
   * Init the process of creating a new machine category
   */
  const addMachineCategory = (): void => {
    setMachineCategory({} as MachineCategory);
    setModalIsOpen(true);
  };

  /**
   * Init the process of editing the given machine category
   */
  const editMachineCategory = (category: MachineCategory): () => void => {
    return (): void => {
      setMachineCategory(category);
      setModalIsOpen(true);
    };
  };

  /**
   * Callback triggred when the current machine category was successfully deleted
   */
  const onDestroySuccess = (message: string): void => {
    MachineCategoryAPI.index().then(data => {
      setMachineCategories(data);
      onSuccess(message);
    }).catch((error) => {
      onError('Unable to load machine categories' + error);
    });
  };

  return (
    <div className="machine-categories-list">
      <header>
        <h2>{t('app.admin.machine_categories_list.machine_categories')}</h2>
        <div className='grpBtn'>
          <FabButton className="main-action-btn" onClick={addMachineCategory}>{t('app.admin.machine_categories_list.add_a_machine_category')}</FabButton>
        </div>
      </header>
      <MachineCategoryModal isOpen={modalIsOpen}
                            machineCategory={machineCategory}
                            toggleModal={toggleCreateAndEditModal}
                            onSuccess={onSaveTypeSuccess}
                            onError={onError} />
      <table className="machine-categories-table">
        <thead>
          <tr>
            <th style={{ width: '50%' }}>{t('app.admin.machine_categories_list.name')}</th>
            <th style={{ width: '30%' }}>{t('app.admin.machine_categories_list.machines_number')}</th>
            <th style={{ width: '20%' }}></th>
          </tr>
        </thead>
        <tbody>
          {machineCategories.map(category => {
            return (
              <tr key={category.id}>
                <td>
                  <span>{category.name}</span>
                </td>
                <td>
                  <span>{category.machine_ids.length}</span>
                </td>
                <td>
                  <div className="buttons">
                    <EditDestroyButtons onDeleteSuccess={onDestroySuccess}
                                        onError={onError}
                                        onEdit={editMachineCategory(category)}
                                        itemId={category.id}
                                        itemType={t('app.admin.machine_categories_list.machine_category')}
                                        apiDestroy={MachineCategoryAPI.destroy} />
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

const MachineCategoriesListWrapper: React.FC<MachineCategoriesListProps> = (props) => {
  return (
    <Loader>
      <MachineCategoriesList {...props} />
    </Loader>
  );
};

Application.Components.component('machineCategoriesList', react2angular(MachineCategoriesListWrapper, ['onError', 'onSuccess']));
