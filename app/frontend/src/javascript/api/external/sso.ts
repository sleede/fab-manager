import ssoClient from '../clients/sso-client';
import { AxiosResponse } from 'axios';
import { OpenIdConfiguration } from '../../models/sso';

export default class SsoClient {
  /**
   * @see https://openid.net/specs/openid-connect-discovery-1_0.html
   */
  static async openIdConfiguration (host: string): Promise<OpenIdConfiguration> {
    const res: AxiosResponse<OpenIdConfiguration> = await ssoClient(host).get('.well-known/openid-configuration');
    return res?.data;
  }
}
