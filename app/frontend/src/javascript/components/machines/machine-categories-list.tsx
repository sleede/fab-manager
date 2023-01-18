import React, { useEffect, useState } from 'react';
import { MachineCategory } from '../../models/machine-category';
import { Machine } from '../../models/machine';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import MachineCategoryAPI from '../../api/machine-category';
import MachineAPI from '../../api/machine';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { MachineCategoryModal } from './machine-category-modal';
import { DeleteMachineCategoryModal } from './delete-machine-category-modal';

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
  // all machines, for assign to category
  const [machines, setMachines] = useState<Array<Machine>>([]);
  // creation/edition modal
  const [modalIsOpen, setModalIsOpen] = useState<boolean>(false);
  // currently added/edited category
  const [machineCategory, setMachineCategory] = useState<MachineCategory>(null);
  // deletion modal
  const [destroyModalIsOpen, setDestroyModalIsOpen] = useState<boolean>(false);
  // currently deleted machine category
  const [machineCategoryId, setMachineCategoryId] = useState<number>(null);

  // retrieve the full list of machine categories on component mount
  useEffect(() => {
    MachineCategoryAPI.index()
      .then(data => setMachineCategories(data))
      .catch(e => onError(e));
    MachineAPI.index()
      .then(data => setMachines(data))
      .catch(e => onError(e));
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
   * Init the process of deleting a machine category (ask for confirmation)
   */
  const destroyMachineCategory = (id: number): () => void => {
    return (): void => {
      setMachineCategoryId(id);
      setDestroyModalIsOpen(true);
    };
  };

  /**
   * Open/closes the confirmation before deletion modal
   */
  const toggleDestroyModal = (): void => {
    setDestroyModalIsOpen(!destroyModalIsOpen);
  };

  /**
   * Callback triggred when the current machine category was successfully deleted
   */
  const onDestroySuccess = (message: string): void => {
    setDestroyModalIsOpen(false);
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
                            machines={machines}
                            machineCategory={machineCategory}
                            toggleModal={toggleCreateAndEditModal}
                            onSuccess={onSaveTypeSuccess}
                            onError={onError} />
      <DeleteMachineCategoryModal isOpen={destroyModalIsOpen}
                                  machineCategoryId={machineCategoryId}
                                  toggleModal={toggleDestroyModal}
                                  onSuccess={onDestroySuccess}
                                  onError={onError}/>
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
                    <FabButton className="edit-btn" onClick={editMachineCategory(category)}>
                      <i className="fa fa-edit" /> {t('app.admin.machine_categories_list.edit')}
                    </FabButton>
                    <FabButton className="delete-btn" onClick={destroyMachineCategory(category.id)}>
                      <i className="fa fa-trash" />
                    </FabButton>
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
