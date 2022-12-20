import { User } from '../../../app/frontend/src/javascript/models/user';

export const admins: Array<User> = [
  { id: 1, name: 'Jean Dupont', group_id: 1, role: 'admin', email: 'jean.dupont@example.com', profile_attributes: { id: 1, first_name: 'Jean', last_name: 'Dupont' }, invoicing_profile_attributes: { address_attributes: { address: '11 rue des poireaux, 12340 Trilouilly-les-oies' } } },
  { id: 2, name: 'Germain Durand', group_id: 2, role: 'admin', email: 'germain.durand@example.com', profile_attributes: { id: 2, first_name: 'Germain', last_name: 'Durand' }, invoicing_profile_attributes: { address_attributes: { address: '12 rue des navets, 23450 Trilouilly-les-canards' } } }
];

export const managers: Array<User> = [
  { id: 3, name: 'Louison Bobet', group_id: 1, role: 'manager', email: 'louison.bobet@example.com', profile_attributes: { id: 1, first_name: 'Louison', last_name: 'Bobet' }, invoicing_profile_attributes: { address_attributes: { address: '13 rue des carottes, 34560 Trilouilly-les-poules' } } },
  { id: 4, name: 'Marlene Dietrich', group_id: 2, role: 'manager', email: 'marlene.dietrich@example.com', profile_attributes: { id: 4, first_name: 'Marlene', last_name: 'Dietrich' }, invoicing_profile_attributes: { address_attributes: { address: '14 rue des patates, 45670 Trilouilly-les-pintades' } } }
];

export const partners: Array<User> = [
  { id: 5, name: 'Arthur Rimbaud', group_id: 1, role: 'partner', email: 'arthur.rimbaud@example.com', profile_attributes: { id: 5, first_name: 'Arthur', last_name: 'Rimbaud' }, invoicing_profile_attributes: { address_attributes: { address: '15 rue des choux-raves, 56780 Trilouilly-les-cailles' } } },
  { id: 6, name: 'Stanislas Leszczynski', group_id: 1, role: 'partner', email: 'stanislas.leszczynski@example.com', profile_attributes: { id: 6, first_name: 'Stanislas', last_name: 'Leszczynski' }, invoicing_profile_attributes: { address_attributes: { address: '16 rue des blettes, 67890 Trilouilly-les-dindes' } } }
];

export const members: Array<User> = [
  { id: 7, name: 'Victor Hugo', group_id: 1, role: 'member', email: 'victor.hugo@example.com', profile_attributes: { id: 7, first_name: 'Victor', last_name: 'Hugo' }, invoicing_profile_attributes: { address_attributes: { address: '17 rue des radis, 78910 Trilouilly-les-pigeons' } } },
  { id: 8, name: 'Paul Verlaine', group_id: 2, role: 'member', email: 'paul.verlaine@example.com', profile_attributes: { id: 8, first_name: 'Paul', last_name: 'Verlaine' }, invoicing_profile_attributes: { address_attributes: { address: '18 rue des topinambours, 89120 Trilouilly-les-lapins' } } },
  { id: 9, name: 'Alfred de Vigny', group_id: 1, role: 'member', email: 'alfred.de.vigny@example.com', profile_attributes: { id: 9, first_name: 'Alfred', last_name: 'de Vigny' }, invoicing_profile_attributes: { address_attributes: { address: '19 rue des choux-fleurs, 91230 Trilouilly-les-dindons' } } },
  { id: 10, name: 'Madeleine De Scudéry', group_id: 2, role: 'member', email: 'madeleine.de.scudery@example.com', profile_attributes: { id: 10, first_name: 'Madeleine', last_name: 'de Scudéry' }, invoicing_profile_attributes: { address_attributes: { address: '20 rue des céleris, 12450 Trilouilly-les-faisans' } } },
  { id: 11, name: 'Marie-Olympe De Gouges', group_id: 1, role: 'member', email: 'marie-olympe.de.gouges@example.com', profile_attributes: { id: 11, first_name: 'Marie-Olympe', last_name: 'de Gouges' }, invoicing_profile_attributes: { address_attributes: { address: '21 rue des artichauts, 12560 Trilouilly-les-autruches' } } },
  { id: 12, name: 'Charles Fourier', group_id: 2, role: 'member', email: 'charles.fourier@example.com', profile_attributes: { id: 12, first_name: 'Charles', last_name: 'Fourier' }, invoicing_profile_attributes: { address_attributes: { address: '22 rue des brocolis, 12780 Trilouilly-les-émeus' } } },
  { id: 13, name: 'Louise Michel', group_id: 1, role: 'member', email: 'louise.michel@example.com', profile_attributes: { id: 13, first_name: 'Louise', last_name: 'Michel' }, invoicing_profile_attributes: { address_attributes: { address: '23 rue des courgettes, 12780 Trilouilly-les-nandous' } } },
  { id: 14, name: 'Hélène Bouvier', group_id: 2, role: 'member', email: 'helene.bouvier@example.com', profile_attributes: { id: 14, first_name: 'Hélène', last_name: 'Bouvier' }, invoicing_profile_attributes: { address_attributes: { address: '24 rue des cornichons, 12780 Trilouilly-les-grenouilles' } } }
];

export const users = members.concat(managers).concat(admins);

export default users.concat(partners);
