import apiClient from './api-client';
import { AxiosResponse } from 'axios';

export default class PayzenAPI {

  static async chargeSDKTest(baseURL: string, username: string, password: string): Promise<any> {
    const res: AxiosResponse = await apiClient.post('/api/payzen/sdk_test', { base_url: baseURL, username, password });
    return res?.data;
  }
}
