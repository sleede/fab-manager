import React, { BaseSyntheticEvent, useState } from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { LabelledInput } from '../base/labelled-input';
import { Loader } from '../base/loader';
import { FabAlert } from '../base/fab-alert';

interface EditPlanCategoryProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  category: PlanCategory
}

/**
 * This component shows an edit button.
 * When clicked, we show a modal dialog allowing to edit the parameters of the provided plan-category.
 */
const EditPlanCategoryComponent: React.FC<EditPlanCategoryProps> = ({ onSuccess, onError, category }) => {
  const { t } = useTranslation('admin');

  // is the edition modal open?
  const [editionModal, setEditionModal] = useState<boolean>(false);
  // when editing, we store the category here, until the edition is over
  const [tempCategory, setTempCategory] = useState<PlanCategory>(category);

  /**
   * Opens/closes the edition modal
   */
  const toggleEditionModal = (): void => {
    setEditionModal(!editionModal);
  };

  /**
   * The edit has been confirmed by the user.
   * Call the API to trigger the update of the temporary set plan-category
   */
  const onEditConfirmed = (): void => {
    PlanCategoryAPI.update(tempCategory).then((updatedCategory) => {
      onSuccess(t('app.admin.edit_plan_category.category_updated'));
      setTempCategory(updatedCategory);
      toggleEditionModal();
    }).catch((error) => {
      onError(t('app.admin.edit_plan_category.unable_to_update') + error);
    });
  };

  /**
   * Callback triggered when the user is changing the name of the category in the modal dialog.
   * We update the name of the temporary-set plan-category, accordingly.
   */
  const onCategoryNameChange = (event: BaseSyntheticEvent) => {
    setTempCategory({ ...tempCategory, name: event.target.value });
  };

  /**
   * Callback triggered when the user is changing the weight of the category in the modal dialog.
   * We update the weight of the temporary-set plan-category, accordingly.
   */
  const onCategoryWeightChange = (event: BaseSyntheticEvent) => {
    setTempCategory({ ...tempCategory, weight: event.target.value });
  };

  return (
    <div className="edit-plan-category">
      <FabButton type='button' className="edit-button" icon={<i className="fa fa-edit" />} onClick={toggleEditionModal} />
      <FabModal title={t('app.admin.edit_plan_category.edit_category')}
        isOpen={editionModal}
        toggleModal={toggleEditionModal}
        className="edit-plan-category-modal"
        closeButton={true}
        confirmButton={t('app.admin.edit_plan_category.confirm_edition')}
        onConfirm={onEditConfirmed}>
        {tempCategory && <div>
          <label htmlFor="category-name">{t('app.admin.edit_plan_category.name')}</label>
          <LabelledInput id="category-name"
            type="text"
            label={<i className="fa fa-tag" />}
            value={tempCategory.name}
            onChange={onCategoryNameChange} />
          <label htmlFor="category-weight">{t('app.admin.edit_plan_category.significance')}</label>
          <LabelledInput id="category-weight"
            type="number"
            label={<i className="fa fa-sort-numeric-desc" />}
            value={tempCategory.weight}
            onChange={onCategoryWeightChange} />
        </div>}
        <FabAlert level="info" className="significance-info">
          {t('app.admin.edit_plan_category.significance_info')}
        </FabAlert>
      </FabModal>
    </div>
  );
};

export const EditPlanCategory: React.FC<EditPlanCategoryProps> = ({ onSuccess, onError, category }) => {
  return (
    <Loader>
      <EditPlanCategoryComponent onSuccess={onSuccess} onError={onError} category={category} />
    </Loader>
  );
};
