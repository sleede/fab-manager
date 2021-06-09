import React, { ReactNode, useEffect, useState } from 'react';
import _ from 'lodash';
import PlanAPI from '../../api/plan';
import { Plan } from '../../models/plan';
import { PlanCategory } from '../../models/plan-category';
import PlanCategoryAPI from '../../api/plan-category';
import { User } from '../../models/user';
import { Group } from '../../models/group';
import GroupAPI from '../../api/group';
import { PlanCard } from './plan-card';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { useTranslation } from 'react-i18next';

declare var Application: IApplication;

interface PlansListProps {
  onError: (message: string) => void,
  onPlanSelection: (plan: Plan) => void,
  onLoginRequest: () => void,
  operator?: User,
  customer?: User,
  subscribedPlanId?: number,
}

// A list of plans, organized by group ID - then organized by plan-category ID (or NaN if the plan has no category)
type PlansTree = Map<number, Map<number, Array<Plan>>>;

/**
 * This component display an organized list of plans to allow the end-user to select one and subscribe online
 */
const PlansList: React.FC<PlansListProps> = ({ onError, onPlanSelection, onLoginRequest, operator, customer, subscribedPlanId }) => {
  const { t } = useTranslation('public');

  // all plans
  const [plans, setPlans] = useState<PlansTree>(null);
  // all plan-categories, ordered by weight
  const [planCategories, setPlanCategories] = useState<Array<PlanCategory>>(null);
  // all groups
  const [groups, setGroups] = useState<Array<Group>>(null);
  // currently selected plan
  const [selectedPlan, setSelectedPlan] = useState<Plan>(null);

  // fetch data on component mounted
  useEffect(() => {
    PlanCategoryAPI.index()
      .then(data => setPlanCategories(data))
      .catch(error => onError(error));
    GroupAPI.index()
      .then(groupsData => {
        setGroups(groupsData);
        PlanAPI.index()
          .then(data => setPlans(sortPlans(data, groupsData)))
          .catch(error => onError(error));
      })
      .catch(error => onError(error))
  }, []);

  // reset the selected plan when the user changes
  useEffect(() => {
    setSelectedPlan(null);
  }, [customer, operator]);

  /**
   * Group a flat array of plans and return a collection of the same plans, grouped by the given property
   */
  const groupBy = (plans: Array<Plan>, criteria: string): Map<number, Array<Plan>> => {
    const grouped = _.groupBy(plans, criteria);

    const map = new Map<number, Array<Plan>>();
    for (const criteriaId in grouped) {
      if (Object.prototype.hasOwnProperty.call(grouped, criteriaId)) {
        const enabled = grouped[criteriaId].filter(plan => !plan.disabled);
        // null ids will be converted to NaN
        map.set(Number(criteriaId), enabled);
      }
    }
    return map;
  };

  /**
   * Sort the plans, by group and by category and return the corresponding map
   */
  const sortPlans = (plans: Array<Plan>, groups: Array<Group>): PlansTree => {
    const byGroup = groupBy(plans, 'group_id');

    const res = new Map<number, Map<number, Array<Plan>>>();
    for (const [groupId, plansByGroup] of byGroup) {
      const group = groups.find(g => g.id === groupId);
      if (!group.disabled) {
        res.set(groupId, groupBy(plansByGroup, 'plan_category_id'));
      }
    }
    return res;
  }

  /**
   * Filter the plans to display, depending on the connected/selected user
   */
  const filteredPlans = (): PlansTree => {
    if (_.isEmpty(customer)) return plans;

    return new Map([[customer.group_id, plans.get(customer.group_id)]]);
  }

  /**
   * When called with a group ID, returns the name of the requested group
   */
  const groupName = (groupId: number): string => {
    return groups.find(g => g.id === groupId)?.name;
  }

  /**
   * When called with a category ID, returns the name of the requested plan-category
   */
  const categoryName = (categoryId: number): string => {
    return planCategories.find(c => c.id === categoryId)?.name;
  }

  /**
   * Check if the currently selected plan matched the provided one
   */
  const isSelectedPlan = (plan: Plan): boolean => {
    return (plan === selectedPlan);
  }

  /**
   * Callback for sorting plans by weight
   * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
   */
  const comparePlans = (plan1: Plan, plan2: Plan): number => {
    return (plan2.ui_weight - plan1.ui_weight);
  }

  /**
   * Callback for sorting categories by weight
   * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
   */
  const compareCategories = (category1: [number, Array<Plan>], category2: [number, Array<Plan>]): number => {
    if (isNaN(category1[0])) return -1;
    if (isNaN(category2[0])) return 1;

    const categoryObject1 = planCategories.find(c => c.id === category1[0]);
    const categoryObject2 = planCategories.find(c => c.id === category2[0]);
    return (categoryObject2.weight - categoryObject1.weight);
  }

  /**
   * Callback triggered when the user chooses a plan to subscribe
   */
  const handlePlanSelection = (plan: Plan): void => {
    setSelectedPlan(plan);
    onPlanSelection(plan);
  }

  /**
   * Render the provided list of categories, with each associated plans
   */
  const renderPlansByCategory = (plans: Map<number, Array<Plan>>): ReactNode => {
    return (
      <div className="list-of-categories">
        {Array.from(plans).sort(compareCategories).map(([categoryId, plansByCategory]) => {
          return (
            <div key={categoryId} className={`plans-per-category ${categoryId ? 'with-category' : 'no-category' }`}>
              {!!categoryId && <h3 className="category-title">{ categoryName(categoryId) }</h3>}
              {renderPlans(plansByCategory)}
            </div>
          )
        })}
      </div>
    );
  }

  /**
   * Render the provided list of plans, ordered by ui_weight.
   */
  const renderPlans = (categoryPlans: Array<Plan>): ReactNode => {
    return (
      <div className="list-of-plans">
        {categoryPlans.length === 0 && <span className="no-plans">
          {t('app.public.plans.no_plans')}
        </span>}
        {categoryPlans.sort(comparePlans).map(plan => (
          <PlanCard key={plan.id}
                    userId={customer?.id}
                    subscribedPlanId={subscribedPlanId}
                    plan={plan}
                    operator={operator}
                    isSelected={isSelectedPlan(plan)}
                    onSelectPlan={handlePlanSelection}
                    onLoginRequested={onLoginRequest} />
        ))}
      </div>
    );
  }

  return (
    <div className="plans-list">
      {plans && Array.from(filteredPlans()).map(([groupId, plansByGroup]) => {
        return (
          <div key={groupId} className="plans-per-group">
            <h2 className="group-title">{ groupName(groupId) }</h2>
            {renderPlansByCategory(plansByGroup)}
          </div>
        )
      })}
    </div>
  );
}


const PlansListWrapper: React.FC<PlansListProps> = ({ customer, onError, onPlanSelection, onLoginRequest, operator, subscribedPlanId }) => {
  return (
    <Loader>
      <PlansList customer={customer} onError={onError} onPlanSelection={onPlanSelection} onLoginRequest={onLoginRequest} operator={operator} subscribedPlanId={subscribedPlanId} />
    </Loader>
  );
}

Application.Components.component('plansList', react2angular(PlansListWrapper, ['customer', 'onError', 'onPlanSelection', 'onLoginRequest', 'operator', 'subscribedPlanId']));
