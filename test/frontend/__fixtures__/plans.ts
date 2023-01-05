import { Plan } from '../../../app/frontend/src/javascript/models/plan';

const plans: Array<Plan> = [
  {
    id: 1,
    base_name: 'Hello',
    name: 'Hello - 1 month',
    interval: 'month',
    interval_count: 1,
    group_id: 1,
    plan_category_id: 1,
    training_credit_nb: 2,
    is_rolling: true,
    description: 'Lorem ipsum dolor sit amet',
    type: 'Plan',
    ui_weight: 10,
    disabled: false,
    monthly_payment: false,
    amount: 15,
    prices_attributes: [
      { id: 1, group_id: 1, plan_id: 1, priceable_type: 'Machine', priceable_id: 1, amount: 10, duration: 60 },
      { id: 2, group_id: 1, plan_id: 1, priceable_type: 'Machine', priceable_id: 2, amount: 12.3, duration: 60 },
      { id: 3, group_id: 1, plan_id: 1, priceable_type: 'Space', priceable_id: 1, amount: 21.2, duration: 60 },
      { id: 4, group_id: 1, plan_id: 1, priceable_type: 'Space', priceable_id: 2, amount: 8.4, duration: 60 }
    ],
    plan_file_attributes: {}
  },
  {
    id: 2,
    base_name: 'Hardcore',
    name: 'Hardcore - 1 year',
    interval: 'year',
    interval_count: 1,
    group_id: 1,
    plan_category_id: 2,
    training_credit_nb: 4,
    is_rolling: true,
    description: 'Lorem ipsum dolor sit amet consectetur',
    type: 'PartnerPlan',
    ui_weight: 5,
    disabled: false,
    monthly_payment: true,
    amount: 229,
    prices_attributes: [
      { id: 5, group_id: 1, plan_id: 2, priceable_type: 'Machine', priceable_id: 1, amount: 8, duration: 60 },
      { id: 6, group_id: 1, plan_id: 2, priceable_type: 'Machine', priceable_id: 2, amount: 10.3, duration: 60 },
      { id: 7, group_id: 1, plan_id: 2, priceable_type: 'Space', priceable_id: 1, amount: 19.2, duration: 60 },
      { id: 8, group_id: 1, plan_id: 2, priceable_type: 'Space', priceable_id: 2, amount: 6.4, duration: 60 }
    ],
    plan_file_attributes: {},
    partner_id: 5,
    partners: [
      { first_name: 'Arthur', last_name: 'Rimbaud', email: 'arthur.rimbaud@example.com' }
    ]
  }
];

export default plans;
