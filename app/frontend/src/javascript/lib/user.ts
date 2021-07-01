import { User, UserRole } from '../models/user';

export default class UserLib {
  private user: User;

  constructor (user: User) {
    this.user = user;
  }

  /**
   * Check if the current user has privileged access for resources concerning the provided customer
   */
  isPrivileged = (customer: User): boolean => {
    if (this.user.role === UserRole.Admin) return true;

    if (this.user.role === UserRole.Manager) {
      return (this.user.id !== customer.id);
    }

    return false;
  }
}
