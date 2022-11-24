import { User } from '../../../app/frontend/src/javascript/models/user';

export const admins: Array<User> = [
  { id: 1, name: 'Jean Dupont', group_id: 1, role: 'admin', email: 'jean.dupont@example.com', profile_attributes: { id: 1, first_name: 'Jean', last_name: 'Dupont' } },
  { id: 2, name: 'Germain Durand', group_id: 2, role: 'admin', email: 'germain.durand@example.com', profile_attributes: { id: 2, first_name: 'Germain', last_name: 'Durand' } }
];

export const managers: Array<User> = [
  { id: 3, name: 'Louison Bobet', group_id: 1, role: 'manager', email: 'louison.bobet@example.com', profile_attributes: { id: 1, first_name: 'Louison', last_name: 'Bobet' } },
  { id: 4, name: 'Marlene Dietrich', group_id: 2, role: 'manager', email: 'marlene.dietrich@example.com', profile_attributes: { id: 4, first_name: 'Marlene', last_name: 'Dietrich' } }
];

export const partners: Array<User> = [
  { id: 5, name: 'Arthur Rimbaud', group_id: 1, role: 'partner', email: 'arthur.rimbaud@example.com', profile_attributes: { id: 5, first_name: 'Arthur', last_name: 'Rimbaud' } },
  { id: 6, name: 'Stanislas Leszczynski', group_id: 1, role: 'partner', email: 'stanislas.leszczynski@example.com', profile_attributes: { id: 6, first_name: 'Stanislas', last_name: 'Leszczynski' } }
];

export const members: Array<User> = [
  { id: 7, name: 'Victor Hugo', group_id: 1, role: 'member', email: 'victor.hugo@example.com', profile_attributes: { id: 7, first_name: 'Victor', last_name: 'Hugo' } },
  { id: 8, name: 'Paul Verlaine', group_id: 2, role: 'member', email: 'paul.verlaine@example.com', profile_attributes: { id: 8, first_name: 'Paul', last_name: 'Verlaine' } },
  { id: 9, name: 'Alfred de Vigny', group_id: 1, role: 'member', email: 'alfred.de.vigny@example.com', profile_attributes: { id: 9, first_name: 'Alfred', last_name: 'de Vigny' } },
  { id: 10, name: 'Madeleine De Scudéry', group_id: 2, role: 'member', email: 'madeleine.de.scudery@example.com', profile_attributes: { id: 10, first_name: 'Madeleine', last_name: 'de Scudéry' } },
  { id: 11, name: 'Marie-Olympe De Gouges', group_id: 1, role: 'member', email: 'marie-olympe.de.gouges@example.com', profile_attributes: { id: 11, first_name: 'Marie-Olympe', last_name: 'de Gouges' } },
  { id: 12, name: 'Charles Fourier', group_id: 2, role: 'member', email: 'charles.fourier@example.com', profile_attributes: { id: 12, first_name: 'Charles', last_name: 'Fourier' } },
  { id: 13, name: 'Louise Michel', group_id: 1, role: 'member', email: 'louise.michel@example.com', profile_attributes: { id: 13, first_name: 'Louise', last_name: 'Michel' } },
  { id: 14, name: 'Hélène Bouvier', group_id: 2, role: 'member', email: 'helene.bouvier@example.com', profile_attributes: { id: 14, first_name: 'Hélène', last_name: 'Bouvier' } }
];

export const users = members.concat(managers).concat(admins);

export default users.concat(partners);
