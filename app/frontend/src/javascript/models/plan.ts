import { Price } from './price';
import { FileType } from './file';

export type Interval = 'year' | 'month' | 'week';

export type PlanType = 'Plan' | 'PartnerPlan';

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
    group_id: number|'all',
    plan_category_id: number,
    training_credit_nb: number,
    is_rolling: boolean,
    description: string,
    type: PlanType,
    ui_weight: number,
    disabled: boolean,
    monthly_payment: boolean
    amount: number
    prices_attributes: Array<Price>,
    plan_file_attributes: FileType,
    plan_file_url?: string,
    partner_id?: number,
    partners?: Array<Partner>
}

export interface PlansDuration {
    name: string,
    plans_ids: Array<number>
}
