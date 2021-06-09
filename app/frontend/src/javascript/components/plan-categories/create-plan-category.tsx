import React, { BaseSyntheticEvent, useState } from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { LabelledInput } from '../base/labelled-input';
import { Loader } from '../base/loader';
import { FabAlert } from '../base/fab-alert';


interface CreatePlanCategoryProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog allowing to fill the parameters with a new plan-category.
 */
const CreatePlanCategoryComponent: React.FC<CreatePlanCategoryProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [category, setCategory] = useState<PlanCategory>(null);
  // is the creation modal open?
  const [isOpen, setIsOpen] = useState<boolean>(false);

  /**
   * Opens/closes the new plan-category (creation) modal
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * The creation has been confirmed by the user.
   * Push the new plan-category to the API.
   */
  const onCreateConfirmed = (): void => {
    PlanCategoryAPI.create(category).then(() => {
      onSuccess(t('app.admin.create_plan_category.category_created'));
      resetCategory();
      toggleModal();
    }).catch((error) => {
      onError(t('app.admin.create_plan_category.unable_to_create') + error);
    });
  };

  /**
   * Callback triggered when the user is changing the name of the category in the modal dialog.
   * We update the name of the temporary-set plan-category, accordingly.
   */
  const onCategoryNameChange = (event: BaseSyntheticEvent) => {
    setCategory({...category, name: event.target.value });
  };

  /**
   * Callback triggered when the user is changing the weight of the category in the modal dialog.
   * We update the weight of the temporary-set plan-category, accordingly.
   */
  const onCategoryWeightChange = (event: BaseSyntheticEvent) => {
    setCategory({...category, weight: event.target.value });
  };

  /**
   * Initialize a new plan-category for creation
   */
  const initCategoryCreation = () => {
    setCategory({ name: '', weight: 0 });
  };

  /**
   * Reinitialize the category to prevent ghost data
   */
  const resetCategory = () => {
    setCategory(null);
  }

  return (
    <div className="create-plan-category">
      <FabButton type='button'
                 icon={<i className='fa fa-plus' />}
                 className="add-category"
                 onClick={toggleModal}>
        {t('app.admin.create_plan_category.new_category')}
      </FabButton>
      <FabModal title={t('app.admin.create_plan_category.new_category')}
                className="create-plan-category-modal"
                isOpen={isOpen}
                toggleModal={toggleModal}
                closeButton={true}
                confirmButton={t('app.admin.create_plan_category.confirm_create')}
                onConfirm={onCreateConfirmed}
                onCreation={initCategoryCreation}>
        {category && <div>
          <label htmlFor="name">{t('app.admin.create_plan_category.name')}</label>
          <LabelledInput id="name"
                         label={<i className="fa fa-tag" />}
                         type="text"
                         value={category.name}
                         onChange={onCategoryNameChange} />
          <label htmlFor="weight">{t('app.admin.create_plan_category.significance')}</label>
          <LabelledInput id="weight"
                         type="number"
                         label={<i className="fa fa-sort-numeric-desc" />}
                         value={category.weight}
                         onChange={onCategoryWeightChange} />
        </div>}
        <FabAlert level="info" className="significance-info">
          {t('app.admin.create_plan_category.significance_info')}
        </FabAlert>
      </FabModal>
    </div>
  )
};

export const CreatePlanCategory: React.FC<CreatePlanCategoryProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <CreatePlanCategoryComponent onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
}
