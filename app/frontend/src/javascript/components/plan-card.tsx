/**
 * This component is a "card" publicly presenting the details of a plan
 */

import React from 'react';
import { react2angular } from 'react2angular';
import { IFilterService } from 'angular';
import moment from 'moment';
import _ from 'lodash'
import { IApplication } from '../models/application';
import { Plan } from '../models/plan';
import { User, UserRole } from '../models/user';

declare var Application: IApplication;

interface PlanCardProps {
  plan: Plan,
  user: User,
  operator: User,
  isSelected: boolean,
  onSelectPlan: (plan: Plan) => void,
  _t: (key: string, interpolation?: object) => Promise<string>,
  $filter: IFilterService
}

const PlanCard: React.FC<PlanCardProps> = ({ plan, user, operator, onSelectPlan, isSelected, _t, $filter }) => {
  /**
   * Return the formatted localized amount of the given plan (eg. 20.5 => "20,50 €")
   */
  const amount = () : string => {
    return $filter('currency')(plan.amount);
  }
  /**
   * Return the formatted localized duration of te given plan (eg. Month/3 => "3 mois")
   */
  const duration = (): string => {
    return moment.duration(plan.interval_count, plan.interval).humanize();
  }
  /**
   * Check if the user can subscribe to the current plan, for himself
   */
  const canSubscribeForMe = (): boolean => {
    return operator?.role === UserRole.Member || (operator?.role === UserRole.Manager && user?.id === operator?.id)
  }
  /**
   * Check if the user can subscribe to the current plan, for someone else
   */
  const canSubscribeForOther = (): boolean => {
    return operator?.role === UserRole.Admin || (operator?.role === UserRole.Manager && user?.id !== operator?.id)
  }
  /**
   * Check it the user has subscribed to this plan or not
   */
  const hasSubscribedToThisPlan = (): boolean => {
    return user?.subscription?.plan?.id === plan.id;
  }
  /**
   * Callback triggered when the user select the plan
   */
  const handleSelectPlan = (): void => {
    onSelectPlan(plan);
  }
  return (
    <div>
      <h3 className="title">{plan.base_name}</h3>
      <div className="content">
        <div className="wrap">
          <div className="price">
            <div className="amount">{amount()}</div>
            <span className="period">{duration()}</span>
          </div>
        </div>
      </div>
      {canSubscribeForMe() && <div className="cta-button">
        {!hasSubscribedToThisPlan() && <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                                               onClick={handleSelectPlan}
                                               disabled={!_.isNil(user.subscription)}>
          {user && <span>{_t('app.public.plans.i_choose_that_plan')}</span>}
          {!user && <span>{_t('app.public.plans.i_subscribe_online')}</span>}
        </button>}
        {hasSubscribedToThisPlan() && <button className="subscribe-button" disabled>
          { _t('app.public.plans.i_already_subscribed') }
        </button>}
      </div>}
      {canSubscribeForOther() && <div className="cta-button">
        <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                onClick={handleSelectPlan}
                disabled={_.isNil(user)}>
          <span>{ _t('app.public.plans.i_choose_that_plan') }</span>
        </button>
      </div>}
    </div>
  );
}

Application.Components.component('planCard', react2angular(PlanCard, ['plan', 'user', 'operator', 'onSelectPlan', 'isSelected'], ['_t', '$filter']));
