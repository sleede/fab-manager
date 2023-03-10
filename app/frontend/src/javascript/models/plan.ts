import { Price } from './price';
import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';

export type Interval = 'year' | 'month' | 'week';

export type PlanType = 'Plan' | 'PartnerPlan';

export interface Partner {
    first_name: string,
    last_name: string,
    email: string
}

export type LimitableType = 'Machine'|'MachineCategory';
export interface PlanLimitation {
    id?: number,
    limitable_id: number,
    limitable_type: LimitableType,
    limit: number,
    _modified?: boolean,
    _destroy?: boolean,
}

export interface Plan {
    id?: number,
    base_name: string,
    name?: string,
    interval: Interval,
    interval_count: number,
    all_groups?: boolean,
    group_id: number|'all',
    plan_category_id?: number,
    training_credit_nb?: number,
    is_rolling: boolean,
    description?: string,
    type: PlanType,
    ui_weight: number,
    disabled?: boolean,
    monthly_payment: boolean
    amount: number
    prices_attributes?: Array<Price>,
    plan_file_attributes?: FileType,
    plan_file_url?: string,
    partner_id?: number,
    partnership?: boolean,
    limiting?: boolean,
    partners?: Array<Partner>,
    advanced_accounting_attributes?: AdvancedAccounting,
    plan_limitations_attributes?: Array<PlanLimitation>
}

export interface PlansDuration {
    name: string,
    plans_ids: Array<number>
}
