import { TDateISO, TDateISODate, THours, TMinutes } from '../typings/date-iso';
import { FileType } from './file';
import { AdvancedAccounting } from './advanced-accounting';

export interface EventPriceCategoryAttributes {
  id?: number,
  price_category_id: number,
  amount: number,
  _destroy?: boolean,
  category: EventPriceCategory
}

export type RecurrenceOption = 'none' | 'day' | 'week' | 'month' | 'year';
export type EventType = 'standard' | 'nominative' | 'family';

export interface Event {
  id?: number,
  title: string,
  description: string,
  event_image_attributes: FileType,
  event_files_attributes: Array<FileType>,
  category_id: number,
  category: {
    id: number,
    name: string,
    slug: string
  },
  event_theme_ids?: Array<number>,
  event_themes?: Array<{
    name: string
  }>,
  age_range_id?: number,
  age_range?: {
    name: string
  },
  start_date: TDateISODate | Date,
  start_time: `${THours}:${TMinutes}`,
  end_date: TDateISODate | Date,
  end_time: `${THours}:${TMinutes}`,
  month?: string;
  month_id?: number,
  year?: number,
  all_day?: boolean,
  availability?: {
    id: number,
    start_at: TDateISO,
    end_at: TDateISO
  },
  availability_id: number,
  amount: number,
  event_price_categories_attributes?: Array<EventPriceCategoryAttributes>,
  nb_total_places: number,
  nb_free_places: number,
  recurrence_id?: number,
  updated_at?: TDateISO,
  recurrence_events?: Array<{
    id: number,
    start_date: TDateISODate,
    start_time: `${THours}:${TMinutes}`
    end_date: TDateISODate
    end_time: `${THours}:${TMinutes}`
    nb_free_places: number,
    availability_id: number
  }>,
  recurrence: RecurrenceOption,
  recurrence_end_at: Date,
  advanced_accounting_attributes?: AdvancedAccounting,
  event_type: EventType,
}

export interface EventDecoration {
  id?: number,
  name: string,
  related_to?: number // report the count of events related to the given decoration
}

export type EventTheme = EventDecoration;
export type EventCategory = EventDecoration;
export type AgeRange = EventDecoration;

export interface EventPriceCategory {
  id?: number,
  name: string,
  conditions?: string,
  events?: number,
  created_at?: TDateISO
}

export interface EventUpdateResult {
  action: 'update',
  total: number,
  updated: number,
  details: {
    events: Array<{
      event: Event,
      status: boolean,
      error?: string,
      message?: string
    }>,
    slots: Array<{
      slot: {
        id: number,
        availability_id: number,
        created_at: TDateISO,
        end_at: TDateISO,
        start_at: TDateISO,
        updated_at: TDateISO,
      },
      status: boolean,
      error?: string,
      message?: string
    }>
  }
}
