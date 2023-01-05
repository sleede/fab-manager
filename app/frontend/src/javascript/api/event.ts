import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Event, EventUpdateResult } from '../models/event';
import ApiLib from '../lib/api';

export default class EventAPI {
  static async create (event: Event): Promise<Event> {
    const data = ApiLib.serializeAttachments(event, 'event', ['event_files_attributes', 'event_image_attributes']);
    const res: AxiosResponse<Event> = await apiClient.post('/api/events', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (event: Event, mode: 'single' | 'next' | 'all'): Promise<EventUpdateResult> {
    const data = ApiLib.serializeAttachments(event, 'event', ['event_files_attributes', 'event_image_attributes']);
    data.set('edit_mode', mode);
    const res: AxiosResponse<EventUpdateResult> = await apiClient.put(`/api/events/${event.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }
}
