import { Plan } from './plan';
import { TDateISO, TDateISODate } from '../typings/date-iso';
import { supportedNetworks, SupportedSocialNetwork } from './social-network';

export enum UserRole {
  Member = 'member',
  Manager = 'manager',
  Admin = 'admin'
}

type ProfileAttributesSocial = {
  [network in SupportedSocialNetwork]: string
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
  profile_attributes: ProfileAttributesSocial & {
    id: number,
    first_name: string,
    last_name: string,
    interest: string,
    software_mastered: string,
    phone: string,
    website: string,
    job: string,
    tours: Array<string>,
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

const socialMappings = supportedNetworks.map(network => {
  return { [`profile_attributes.${network}`]: `profile.${network}` };
});

export const UserFieldMapping = Object.assign({
  'profile_attributes.user_avatar_attributes.attachment': 'profile.avatar',
  'statistic_profile_attributes.gender': 'profile.gender',
  'profile_attributes.last_name': 'profile.last_name',
  'profile_attributes.first_name': 'profile.first_name',
  'statistic_profile_attributes.birthday': 'profile.birthday',
  'profile_attributes.phone': 'profile.phone',
  username: 'user.username',
  email: 'user.email',
  'invoicing_profile_attributes.address_attributes.address': 'profile.address',
  'invoicing_profile_attributes.organization_attributes.name': 'profile.organization_name',
  'invoicing_profile_attributes.organization_attributes.address_attributes.address': 'profile.organization_address',
  'profile_attributes.website': 'profile.website',
  'profile_attributes.job': 'profile.job',
  'profile_attributes.interest': 'profile.interest',
  'profile_attributes.software_mastered': 'profile.software_mastered',
  is_allow_contact: 'user.is_allow_contact',
  is_allow_newsletter: 'user.is_allow_newsletter'
}, ...socialMappings);
