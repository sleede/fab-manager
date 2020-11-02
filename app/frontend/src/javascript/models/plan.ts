import { Price } from './price';

export enum Interval {
    Year = 'year',
    Month = 'month',
    Week = 'week'
}

export enum PlanType {
    Plan = 'Plan',
    PartnerPlan = 'PartnerPlan'
}

export interface Partner {
    first_name: string,
    last_name: string,
    email: string
}

export interface Plan {
    id: number,
    base_name: string,
    name: string,
    interval: Interval,
    interval_count: number,
    group_id: number,
    training_credit_nb: number,
    is_rolling: boolean,
    description: string,
    type: PlanType,
    ui_weight: number,
    disabled: boolean,
    monthly_payment: boolean
    amount: number
    prices: Array<Price>,
    plan_file_attributes: {
        id: number,
        attachment_identifier: string
    },
    plan_file_url: string,
    partners: Array<Partner>
}
