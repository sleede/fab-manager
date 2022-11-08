import { isNil, isEmpty } from 'lodash';
import { User } from '../models/user';
import { supportedNetworks, SupportedSocialNetwork } from '../models/social-network';

export default class UserLib {
  private readonly user: User;

  constructor (user: User) {
    this.user = user;
  }

  /**
   * Check if the current user has privileged access for resources concerning the provided customer
   */
  isPrivileged = (customer: User): boolean => {
    if (this.user?.role === 'admin' || this.user?.role === 'manager') {
      return (this.user?.id !== customer.id);
    }

    return false;
  };

  /**
   * Filter social networks from the user's profile
   */
  getUserSocialNetworks = (): { name: string, url: string }[] => {
    if (!this.isUser()) {
      return supportedNetworks.map(network => {
        return { name: network, url: '' };
      });
    }

    const userNetworks = [];
    for (const [name, url] of Object.entries(this.user.profile_attributes)) {
      supportedNetworks.includes(name as SupportedSocialNetwork) && userNetworks.push({ name, url });
    }
    return userNetworks;
  };

  /**
   * Return the email given by the SSO provider, parsed if needed
   * @return {String} E-mail of the current user
   */
  ssoEmail = (): string => {
    const { email } = this.user;
    if (email) {
      const duplicate = email.match(/^<([^>]+)>.{20}-duplicate$/);
      if (duplicate) {
        return duplicate[1];
      }
    }
    return email;
  };

  /**
   * Test if the user's mail is marked as duplicate
   */
  hasDuplicate = (): boolean => {
    const { email } = this.user;
    if (email) {
      return !(email.match(/^<([^>]+)>.{20}-duplicate$/) === null);
    }
  };

  /**
   * Check if the current user is not empty
   */
  private isUser = (): boolean => {
    if (isNil(this.user)) return false;

    return !(isEmpty(this.user.invoicing_profile_attributes) && isEmpty(this.user.statistic_profile_attributes));
  };
}
