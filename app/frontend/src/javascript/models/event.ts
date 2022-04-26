import { TDateISO } from '../typings/date-iso';

export interface Event {
  id: number,
  title: string,
  description: string,
  event_image: string,
  event_files_attributes: Array<{
    id: number,
    attachment: string,
    attachment_url: string
  }>,
  category_id: number,
  category: {
    id: number,
    name: string,
    slug: string
  },
  event_theme_ids: Array<number>,
  event_themes: Array<{
    name: string
  }>,
  age_range_id: number,
  age_range: {
    name: string
  },
  start_date: TDateISO,
  start_time: TDateISO,
  end_date: TDateISO,
  end_time: TDateISO,
  month: string;
  month_id: number,
  year: number,
  all_day: boolean,
  availability: {
    id: number,
    start_at: TDateISO,
    end_at: TDateISO
  },
  availability_id: number,
  amount: number,
  prices: Array<{
    id: number,
    amount: number,
    category: {
      id: number,
      name: string
    }
  }>,
  nb_total_places: number,
  nb_free_places: number
}
