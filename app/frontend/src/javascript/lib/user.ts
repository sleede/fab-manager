import { User } from '../models/user';
import { supportedNetworks, SupportedSocialNetwork } from '../models/social-network';

export default class UserLib {
  private user: User;

  constructor (user: User) {
    this.user = user;
  }

  /**
   * Check if the current user has privileged access for resources concerning the provided customer
   */
  isPrivileged = (customer: User): boolean => {
    if (this.user.role === 'admin') return true;

    if (this.user.role === 'manager') {
      return (this.user.id !== customer.id);
    }

    return false;
  };

  /**
   * Filter social networks from the user's profile
   */
  getUserSocialNetworks = (customer: User): {name: string, url: string}[] => {
    const userNetworks = [];

    for (const [name, url] of Object.entries(customer.profile_attributes)) {
      supportedNetworks.includes(name as SupportedSocialNetwork) && userNetworks.push({ name, url });
    }
    return userNetworks;
  };
}
