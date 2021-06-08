import React, { BaseSyntheticEvent, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { LabelledInput } from '../base/labelled-input';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';

declare var Application: IApplication;

interface PlanCategoriesListProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of all plan-categories and offer to manager them by deleting, modifying
 * and reordering each plan-categories.
 */
export const PlanCategoriesList: React.FC<PlanCategoriesListProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // list of all categories
  const [categories, setCategories] = useState<Array<PlanCategory>>(null);
  // when editing or deleting a category, it will be stored here until the edition is over
  const [tempCategory, setTempCategory] = useState<PlanCategory>(null);
  // is the creation modal open?
  const [creationModal, setCreationModal] = useState<boolean>(false);
  // is the edition modal open?
  const [editionModal, setEditionModal] = useState<boolean>(false);
  // is the deletion modal open?
  const [deletionModal, setDeletionModal] = useState<boolean>(false);

  // load the categories list on component mount
  useEffect(() => {
    refreshCategories();
  }, []);

  /**
   * Opens/closes the new plan-category (creation) modal
   */
  const toggleCreationModal = (): void => {
    setCreationModal(!creationModal);
  };

  /**
   * Opens/closes the edition modal
   */
  const toggleEditionModal = (): void => {
    setEditionModal(!editionModal);
  };

  /**
   * Opens/closes the deletion modal
   */
  const toggleDeletionModal = (): void => {
    setDeletionModal(!deletionModal);
  };

  /**
   * Triggered when the edit-category button is pushed.
   * Set the provided category to the currently edited category then open the edition modal.
   */
  const handleEditCategory = (category: PlanCategory) => {
    return () => {
      setTempCategory(category);
      toggleEditionModal();
    };
  };

  /**
   * Triggered when the delete-category button is pushed.
   * Set the provided category to the currently deleted category then open the deletion modal.
   */
  const handleDeleteCategory = (category: PlanCategory) => {
    return () => {
      setTempCategory(category);
      toggleDeletionModal();
    };
  };

  /**
   * The creation has been confirmed by the user.
   * Push the new plan-category to the API.
   */
  const onCreateConfirmed = (): void => {
    PlanCategoryAPI.create(tempCategory).then(() => {
      onSuccess(t('app.admin.plan_categories_list.category_created'));
      resetTempCategory();
      toggleCreationModal();
      refreshCategories();
    }).catch((error) => {
      onError(t('app.admin.plan_categories_list.unable_to_create') + error);
    });
  };

  /**
   * The deletion has been confirmed by the user.
   * Call the API to trigger the deletion of the temporary set plan-category
   */
  const onDeleteConfirmed = (): void => {
    PlanCategoryAPI.destroy(tempCategory.id).then(() => {
      onSuccess(t('app.admin.plan_categories_list.category_deleted'));
      refreshCategories();
    }).catch((error) => {
      onError(t('app.admin.plan_categories_list.unable_to_delete') + error);
    });
    resetTempCategory();
    toggleDeletionModal();
  };

  /**
   * The edit has been confirmed by the user.
   * Call the API to trigger the update of the temporary set plan-category
   */
  const onEditConfirmed = (): void => {
    PlanCategoryAPI.update(tempCategory).then(() => {
      onSuccess(t('app.admin.plan_categories_list.category_updated'));
      resetTempCategory();
      refreshCategories();
      toggleEditionModal();
    }).catch((error) => {
      onError(t('app.admin.plan_categories_list.unable_to_update') + error);
    });
  };

  /**
   * Callback triggered when the user is changing the name of the category in the modal dialog.
   * We update the name of the temporary-set plan-category, accordingly.
   */
  const onCategoryNameChange = (event: BaseSyntheticEvent) => {
    setTempCategory({...tempCategory, name: event.target.value });
  };

  /**
   * Callback triggered when the user is changing the weight of the category in the modal dialog.
   * We update the weight of the temporary-set plan-category, accordingly.
   */
  const onCategoryWeightChange = (event: BaseSyntheticEvent) => {
    setTempCategory({...tempCategory, weight: event.target.value });
  };

  /**
   * Initialize a new plan-category for creation
   */
  const initCategoryCreation = () => {
    setTempCategory({ name: '', weight: 0 });
  };

  /**
   * Reinitialize the temporary category to prevent ghost data
   */
  const resetTempCategory = () => {
    setTempCategory(null);
  }

  /**
   * Refresh the list of categories
   */
  const refreshCategories = () => {
    PlanCategoryAPI.index().then((data) => {
      setCategories(data);
    }).catch((error) => onError(error));
  };

  return (
    <div className="plan-categories-list">
      <FabButton type='button'
                 icon={<i className='fa fa-plus' />}
                 className="add-category"
                 onClick={toggleCreationModal}>
        {t('app.admin.plan_categories_list.new_category')}
      </FabButton>
      <h3>{t('app.admin.plan_categories_list.categories_list')}</h3>
      <table className="categories-table">
        <tbody>
          {categories && categories.map(c =>
            <tr key={c.id}>
              <td className="category-name">{c.name}</td>
              <td className="category-actions">
                <FabButton type='button' className="edit-button" icon={<i className="fa fa-edit" />} onClick={handleEditCategory(c)} />
                <FabButton type='button' className="delete-button" icon={<i className="fa fa-trash" />} onClick={handleDeleteCategory(c)} />
              </td>
            </tr>)}
        </tbody>
      </table>
      <FabModal title={t('app.admin.plan_categories_list.new_category')}
                 isOpen={creationModal}
                 toggleModal={toggleCreationModal}
                 closeButton={true}
                 confirmButton={t('app.admin.plan_categories_list.confirm_create')}
                 onConfirm={onCreateConfirmed}
                 onCreation={initCategoryCreation}>
        {tempCategory && <div>
          <LabelledInput id="name"
                         label={t('app.admin.plan_categories_list.name')}
                         type="text"
                         value={tempCategory.name}
                         onChange={onCategoryNameChange} />
          <LabelledInput id="weight"
                         type="number"
                         label={t('app.admin.plan_categories_list.significance')}
                         value={tempCategory.weight}
                         onChange={onCategoryWeightChange} />
        </div>}
      </FabModal>
      <FabModal title={t('app.admin.plan_categories_list.delete_category')}
                isOpen={deletionModal}
                toggleModal={toggleDeletionModal}
                closeButton={true}
                confirmButton={t('app.admin.plan_categories_list.confirm_delete')}
                onConfirm={onDeleteConfirmed}>
        <span>{t('app.admin.plan_categories_list.delete_confirmation')}</span>
      </FabModal>
      <FabModal title={t('app.admin.plan_categories_list.edit_category')}
                isOpen={editionModal}
                toggleModal={toggleEditionModal}
                closeButton={true}
                confirmButton={t('app.admin.plan_categories_list.confirm_edition')}
                onConfirm={onEditConfirmed}>
        {tempCategory && <div>
          <LabelledInput id="category-name"
                         type="text"
                         label={t('app.admin.plan_categories_list.name')}
                         value={tempCategory.name}
                         onChange={onCategoryNameChange} />
          <LabelledInput id="category-weight"
                         type="number"
                         label={t('app.admin.plan_categories_list.significance')}
                         value={tempCategory.weight}
                         onChange={onCategoryWeightChange} />
        </div>}
      </FabModal>
    </div>
  )
};


const PlanCategoriesListWrapper: React.FC<PlanCategoriesListProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <PlanCategoriesList onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
}

Application.Components.component('planCategoriesList', react2angular(PlanCategoriesListWrapper, ['onSuccess', 'onError']));
