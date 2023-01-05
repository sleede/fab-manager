import * as React from 'react';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import _ from 'lodash';
import { Plan } from '../../models/plan';
import { User } from '../../models/user';
import { Loader } from '../base/loader';
import '../../lib/i18n';
import FormatLib from '../../lib/format';

interface PlanCardProps {
  plan: Plan,
  userId?: number,
  subscribedPlanId?: number,
  operator: User,
  isSelected: boolean,
  canSelectPlan: boolean,
  onSelectPlan: (plan: Plan) => void,
  onLoginRequested: () => void,
}

/**
 * This component is a "card" (visually), publicly presenting the details of a plan and allowing a user to subscribe.
 */
const PlanCard: React.FC<PlanCardProps> = ({ plan, userId, subscribedPlanId, operator, onSelectPlan, isSelected, onLoginRequested, canSelectPlan }) => {
  const { t } = useTranslation('public');
  /**
   * Return the formatted localized amount of the given plan (eg. 20.5 => "20,50 €")
   */
  const amount = () : string => {
    return FormatLib.price(plan.amount);
  };
  /**
   * Return the formatted localized amount, divided by the number of months (eg. 120 => "10,00 € / month")
   */
  const monthlyAmount = (): string => {
    const monthly = plan.amount / moment.duration(plan.interval_count, plan.interval).asMonths();
    return FormatLib.price(monthly);
  };
  /**
   * Return the formatted localized duration of te given plan (eg. Month/3 => "3 mois")
   */
  const duration = (): string => {
    return moment.duration(plan.interval_count, plan.interval).humanize();
  };
  /**
   * Check if no users are currently logged-in
   */
  const mustLogin = (): boolean => {
    return _.isNil(operator);
  };
  /**
   * Check if the user can subscribe to the current plan, for himself
   */
  const canSubscribeForMe = (): boolean => {
    return operator?.role === 'member' || (operator?.role === 'manager' && userId === operator?.id);
  };
  /**
   * Check if the user can subscribe to the current plan, for someone else
   */
  const canSubscribeForOther = (): boolean => {
    return operator?.role === 'admin' || (operator?.role === 'manager' && userId !== operator?.id);
  };
  /**
   * Check it the user has subscribed to this plan or not
   */
  const hasSubscribedToThisPlan = (): boolean => {
    return subscribedPlanId === plan.id;
  };
  /**
   * Check if the plan has an attached file
   */
  const hasAttachment = (): boolean => {
    return !!plan.plan_file_url;
  };
  /**
   * Check if the plan has a description
   */
  const hasDescription = (): boolean => {
    return !!plan.description;
  };
  /**
   * Check if the plan is allowing a monthly payment schedule
   */
  const canBeScheduled = (): boolean => {
    return plan.monthly_payment;
  };
  /**
   * Callback triggered when the user select the plan
   */
  const handleSelectPlan = (): void => {
    if (canSelectPlan) {
      onSelectPlan(plan);
    }
  };
  /**
   * Callback triggered when a visitor (not logged-in user) select a plan
   */
  const handleLoginRequest = (): void => {
    onLoginRequested();
  };
  return (
    <div className="plan-card">
      <h3 className="title">{plan.base_name}</h3>
      <div className="content">
        {canBeScheduled() && <div className="wrap-monthly">
          <div className="price">
            <div className="amount">{t('app.public.plan_card.AMOUNT_per_month', { AMOUNT: monthlyAmount() })}</div>
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
      <div className="card-footer">
        {hasDescription() && <div className="plan-description" dangerouslySetInnerHTML={{ __html: plan.description }}/>}
        {hasAttachment() && <a className="info-link" href={ plan.plan_file_url } target="_blank" rel="noreferrer">{ t('app.public.plan_card.more_information') }</a>}
        {mustLogin() && <div className="cta-button">
          <button className="subscribe-button" onClick={handleLoginRequest}>{t('app.public.plan_card.i_subscribe_online')}</button>
        </div>}
        {canSubscribeForMe() && <div className="cta-button">
          {!hasSubscribedToThisPlan() && <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
            onClick={handleSelectPlan}
            disabled={!_.isNil(subscribedPlanId)}>
            {t('app.public.plan_card.i_choose_that_plan')}
          </button>}
          {hasSubscribedToThisPlan() && <button className="subscribe-button selected-card" disabled>
            { t('app.public.plan_card.i_already_subscribed') }
          </button>}
        </div>}
        {canSubscribeForOther() && <div className="cta-button">
          <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
            onClick={handleSelectPlan}
            disabled={_.isNil(userId)}>
            <span>{ t('app.public.plan_card.i_choose_that_plan') }</span>
          </button>
        </div>}
      </div>
    </div>
  );
};

const PlanCardWrapper: React.FC<PlanCardProps> = ({ plan, userId, subscribedPlanId, operator, onSelectPlan, isSelected, onLoginRequested, canSelectPlan }) => {
  return (
    <Loader>
      <PlanCard plan={plan} userId={userId} subscribedPlanId={subscribedPlanId} operator={operator} isSelected={isSelected} onSelectPlan={onSelectPlan} onLoginRequested={onLoginRequested} canSelectPlan={canSelectPlan}/>
    </Loader>
  );
};

export { PlanCardWrapper as PlanCard };
