import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { CreatePlanCategory } from './create-plan-category';
import { EditPlanCategory } from './edit-plan-category';
import { DeletePlanCategory } from './delete-plan-category';

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

  // load the categories list on component mount
  useEffect(() => {
    refreshCategories();
  }, []);

  /**
   * The creation/edition/deletion was successful.
   * Show the provided message and refresh the list
   */
  const handleSuccess = (message: string): void => {
    onSuccess(message);
    refreshCategories();
  };

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
      <CreatePlanCategory onSuccess={handleSuccess}
                          onError={onError} />
      <h3>{t('app.admin.plan_categories_list.categories_list')}</h3>
      {categories && categories.length == 0 && <span>{t('app.admin.plan_categories_list.no_categories')}</span>}
      {categories && categories.length > 0 && <table className="categories-table">
        <thead>
          <tr>
            <th style={{ width: '66%' }}>{t('app.admin.plan_categories_list.name')}</th>
            <th>{t('app.admin.plan_categories_list.significance')} <i className="fa fa-sort-numeric-desc" /></th>
          </tr>
        </thead>
        <tbody>
          {categories.map(c =>
            <tr key={c.id}>
              <td className="category-name">{c.name}</td>
              <td className="category-weight">{c.weight}</td>
              <td className="category-actions">
                <EditPlanCategory onSuccess={handleSuccess} onError={onError} category={c} />
                <DeletePlanCategory onSuccess={handleSuccess} onError={onError} category={c} />
              </td>
            </tr>)}
        </tbody>
      </table>}
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
