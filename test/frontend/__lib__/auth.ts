import { User } from '../../../app/frontend/src/javascript/models/user';

declare var loggedUser; // eslint-disable-line no-var

export const loginAs = (user: User) => {
  loggedUser = user; // eslint-disable-line @typescript-eslint/no-unused-vars
};
