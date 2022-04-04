import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { PlanCategory } from '../../models/plan-category';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { Loader } from '../base/loader';
import { PlanCategoryForm } from './plan-category-form';

interface ManagePlanCategoryProps {
  category?: PlanCategory,
  action: 'create' | 'update',
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog allowing to fill the parameters of a plan-category (create new or update existing).
 */
const ManagePlanCategoryComponent: React.FC<ManagePlanCategoryProps> = ({ category, action, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // is the creation modal open?
  const [isOpen, setIsOpen] = useState<boolean>(false);
  // when editing, we store the category here, until the edition is over
  const [tempCategory, setTempCategory] = useState<PlanCategory>(category);

  /**
   * Opens/closes the new plan-category (creation) modal
   */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Initialize a new plan-category for creation
   * or refresh plan-category data for update
   */
  const initCategoryCreation = () => {
    if (action === 'create') {
      setTempCategory({ name: '', description: '', weight: 0 });
    } else {
      setTempCategory(category);
    }
  };

  /**
   * Close the modal if the form submission was successful
   */
  const handleSuccess = (message) => {
    setIsOpen(false);
    onSuccess(message);
  };

  /**
   * Render the appropriate button depending on the action type
   */
  const toggleBtn = () => {
    switch (action) {
      case 'create':
        return (
          <FabButton type='button'
            icon={<i className='fa fa-plus' />}
            className="btn-warning"
            onClick={toggleModal}>
            {t('app.admin.create_plan_category.new_category')}
          </FabButton>
        );
      case 'update':
        return (<FabButton type='button'
          icon={<i className="fa fa-edit" />}
          className="edit-button"
          onClick={toggleModal} />);
    }
  };

  return (
    <div className='manage-plan-category'>
      { toggleBtn() }
      <FabModal title={t(`app.admin.manage_plan_category.${action}_category.title`)}
        isOpen={isOpen}
        toggleModal={toggleModal}
        onCreation={initCategoryCreation}
        closeButton>

        {tempCategory && <PlanCategoryForm action={action} category={tempCategory} onSuccess={handleSuccess} onError={onError} />}

      </FabModal>
    </div>
  );
};

export const ManagePlanCategory: React.FC<ManagePlanCategoryProps> = ({ category, action, onSuccess, onError }) => {
  return (
    <Loader>
      <ManagePlanCategoryComponent category={category} action={action} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};
