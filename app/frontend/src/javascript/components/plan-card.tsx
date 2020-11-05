/**
 * This component is a "card" publicly presenting the details of a plan
 */

import React, { Suspense } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IFilterService } from 'angular';
import moment from 'moment';
import _ from 'lodash'
import { IApplication } from '../models/application';
import { Plan } from '../models/plan';
import { User, UserRole } from '../models/user';
import '../lib/i18n';

declare var Application: IApplication;

interface PlanCardProps {
  plan: Plan,
  user: User,
  operator: User,
  isSelected: boolean,
  onSelectPlan: (plan: Plan) => void,
  $filter: IFilterService
}

const PlanCard: React.FC<PlanCardProps> = ({ plan, user, operator, onSelectPlan, isSelected, $filter }) => {
  const { t } = useTranslation('public');
  /**
   * Return the formatted localized amount of the given plan (eg. 20.5 => "20,50 €")
   */
  const amount = () : string => {
    return $filter('currency')(plan.amount);
  }
  /**
   * Return the formatted localized amount, divided by the number of months (eg. 120 => "10,00 € / month")
   */
  const monthlyAmount = (): string => {
    const monthly = plan.amount / moment.duration(plan.interval_count, plan.interval).asMonths();
    return $filter('currency')(monthly);
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
   * Check if the plan has an attached file
   */
  const hasAttachment = (): boolean => {
    return !!plan.plan_file_url;
  }
  /**
   * Check if the plan is allowing a monthly payment schedule
   */
  const canBeScheduled = (): boolean => {
    return plan.monthly_payment;
  }
  /**
   * Callback triggered when the user select the plan
   */
  const handleSelectPlan = (): void => {
    onSelectPlan(plan);
  }
  return (
    <div className="plan-card">
      <h3 className="title">{plan.base_name}</h3>
      <div className="content">
        {canBeScheduled() && <div className="wrap-monthly">
          <div className="price">
            <div className="amount">{t('app.public.plans.AMOUNT_per_month', {AMOUNT: monthlyAmount()})}</div>
            <span className="period">{duration()}</span>
          </div>
        </div>}
        {!canBeScheduled() && <div className="wrap">
          <div className="price">
            <div className="amount">{amount()}</div>
            <span className="period">{duration()}</span>
          </div>
        </div>}
      </div>
      {canSubscribeForMe() && <div className="cta-button">
        {!hasSubscribedToThisPlan() && <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                                               onClick={handleSelectPlan}
                                               disabled={!_.isNil(user.subscription)}>
          {user && <span>{t('app.public.plans.i_choose_that_plan')}</span>}
          {!user && <span>{t('app.public.plans.i_subscribe_online')}</span>}
        </button>}
        {hasSubscribedToThisPlan() && <button className="subscribe-button" disabled>
          { t('app.public.plans.i_already_subscribed') }
        </button>}
      </div>}
      {canSubscribeForOther() && <div className="cta-button">
        <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                onClick={handleSelectPlan}
                disabled={_.isNil(user)}>
          <span>{ t('app.public.plans.i_choose_that_plan') }</span>
        </button>
      </div>}
      {hasAttachment() && <a className="info-link" href={ plan.plan_file_url } target="_blank">{ t('app.public.plans.more_information') }</a>}
    </div>
  );
}

const PlanCardWrapper: React.FC<PlanCardProps> = ({ plan, user, operator, onSelectPlan, isSelected, $filter }) => {
  const loading = (
    <div className="fa-3x">
      <i className="fas fa-circle-notch fa-spin" />
    </div>
  );
  return (
    <Suspense fallback={loading}>
      <PlanCard plan={plan} user={user} operator={operator} isSelected={isSelected} onSelectPlan={onSelectPlan} $filter={$filter} />
    </Suspense>
  );
}

Application.Components.component('planCard', react2angular(PlanCardWrapper, ['plan', 'user', 'operator', 'onSelectPlan', 'isSelected'], ['$filter']));
