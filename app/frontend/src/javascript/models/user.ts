import { Plan } from './plan';


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
  profile: {
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
    user_avatar: {
      id: number,
      attachment_url: string
    }
  },
  invoicing_profile: {
    id: number,
    address: {
      id: number,
      address: string
    },
    organization: {
      id: number,
      name: string,
      address: {
        id: number,
        address: string
      }
    }
  },
  statistic_profile: {
    id: number,
    gender: string,
    birthday: Date
  },
  subscribed_plan: Plan,
  subscription: {
    id: number,
    expired_at: Date,
    canceled_at: Date,
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
  last_sign_in_at: Date
}
