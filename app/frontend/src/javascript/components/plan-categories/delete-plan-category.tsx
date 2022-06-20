import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { Loader } from '../base/loader';

interface DeletePlanCategoryProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  category: PlanCategory,
}

/**
 * This component shows a button.
 * When clicked, we show a modal dialog to ask the user for confirmation about the deletion of the provided plan-category.
 */
const DeletePlanCategory: React.FC<DeletePlanCategoryProps> = ({ onSuccess, onError, category }) => {
  const { t } = useTranslation('admin');

  const [deletionModal, setDeletionModal] = useState<boolean>(false);

  /**
   * Opens/closes the deletion modal
   */
  const toggleDeletionModal = (): void => {
    setDeletionModal(!deletionModal);
  };

  /**
   * The deletion has been confirmed by the user.
   * Call the API to trigger the deletion of the temporary set plan-category
   */
  const onDeleteConfirmed = (): void => {
    PlanCategoryAPI.destroy(category.id).then(() => {
      onSuccess(t('app.admin.manage_plan_category.delete_category.success'));
    }).catch((error) => {
      onError(t('app.admin.manage_plan_category.delete_category.error') + error);
    });
    toggleDeletionModal();
  };

  return (
    <div className="delete-plan-category">
      <FabButton type='button' className="delete-button" icon={<i className="fa fa-trash" />} onClick={toggleDeletionModal} />
      <FabModal title={t('app.admin.manage_plan_category.delete_category.title')}
        isOpen={deletionModal}
        toggleModal={toggleDeletionModal}
        closeButton={true}
        confirmButton={t('app.admin.manage_plan_category.delete_category.cta')}
        onConfirm={onDeleteConfirmed}>
        <span>{t('app.admin.manage_plan_category.delete_category.confirm')}</span>
      </FabModal>
    </div>
  );
};

const DeletePlanCategoryWrapper: React.FC<DeletePlanCategoryProps> = (props) => {
  return (
    <Loader>
      <DeletePlanCategory {...props} />
    </Loader>
  );
};

export { DeletePlanCategoryWrapper as DeletePlanCategory };
