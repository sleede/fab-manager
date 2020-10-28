/**
 * This component is a "card" publicly presenting the details of a plan
 */

import React from 'react';
import { react2angular } from 'react2angular';
import { IFilterService } from 'angular';
import moment from "moment";
import { IApplication } from '../models/application';
import { Plan } from '../models/plan';

declare var Application: IApplication;

interface PlanCardProps {
  plan: Plan,
  _t: (key: string, interpolation: object) => string,
  $filter: IFilterService
}

const PlanCard: React.FC<PlanCardProps> = ({ plan, _t, $filter }) => {
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
    </div>
  );
}

Application.Components.component('planCard', react2angular(PlanCard, ['plan'], ['_t', '$filter']));
