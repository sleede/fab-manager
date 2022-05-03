import { Plan } from './plan';
import { TDateISO, TDateISODate } from '../typings/date-iso';

export enum UserRole {
  Member = 'member',
  Manager = 'manager',
  Admin = 'admin'
}

export interface User {
  id: number,
  username: string,
  email: string,
  group_id: number,
  role: UserRole
  name: string,
  need_completion: boolean,
  ip_address: string,
  mapped_from_sso?: string[],
  password?: string,
  password_confirmation?: string,
  profile_attributes: {
    id: number,
    first_name: string,
    last_name: string,
    interest: string,
    software_mastered: string,
    phone: string,
    website: string,
    job: string,
    tours: Array<string>,
    facebook: string,
    twitter: string,
    google_plus: string,
    viadeo: string,
    linkedin: string,
    instagram: string,
    youtube: string,
    vimeo: string,
    dailymotion: string,
    github: string,
    echosciences: string,
    pinterest: string,
    lastfm: string,
    flickr: string,
    user_avatar_attributes: {
      id: number,
      attachment?: File,
      attachment_url?: string,
      attachment_files: FileList,
      _destroy?: boolean
    }
  },
  invoicing_profile_attributes: {
    id: number,
    address_attributes: {
      id: number,
      address: string
    },
    organization_attributes: {
      id: number,
      name: string,
      address_attributes: {
        id: number,
        address: string
      }
    }
  },
  statistic_profile_attributes: {
    id: number,
    gender: string,
    birthday: TDateISODate
  },
  subscribed_plan: Plan,
  subscription: {
    id: number,
    expired_at: TDateISO,
    canceled_at: TDateISO,
    stripe: boolean,
    plan: {
      id: number,
      base_name: string,
      name: string,
      interval: string,
      interval_count: number,
      amount: number
    }
  },
  training_credits: Array<number>,
  machine_credits: Array<{machine_id: number, hours_used: number}>,
  last_sign_in_at: TDateISO
}

type OrderingKey = 'last_name' | 'first_name' | 'email' | 'phone' | 'group' | 'plan' | 'id'

export interface UserIndexFilter {
  search?: string,
  filter?: 'inactive_for_3_years' | 'not_confirmed',
  order_by?: OrderingKey | `-${OrderingKey}`,
  page?: number,
  size?: number
}
