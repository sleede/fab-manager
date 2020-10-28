/**
 * This component is a "card" publicly presenting the details of a plan
 */

import React from 'react';
import { react2angular } from 'react2angular';
import Application from '../models/application';
import { Plan } from '../models/plan';

interface PlanCardProps {
  plan: Plan
}

const PlanCard: React.FC<PlanCardProps> = ({ plan }) => {
  return (
    <div>
      <h3 className="title">{plan.base_name}</h3>
      <div className="content">
        <div className="wrap">
          <div className="price">
              {plan.amount}
          </div>
        </div>
      </div>
    </div>
  );
}

Application.Components.component('planCard', react2angular(PlanCard, ['plan']));
