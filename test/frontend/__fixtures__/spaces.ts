import { Space } from '../../../app/frontend/src/javascript/models/space';

const spaces: Array<Space> = [
  {
    id: 1,
    name: 'Biolab',
    description: 'Facilisi vocibus dicit netus mazim ignota hinc iusto dicunt.',
    characteristics: 'Lacus his dictas iaculis tantas similique. Fusce tacimates quidam nostrum discere ne mi salutatus signiferumque mandamus.',
    slug: 'biolab',
    default_places: 4,
    disabled: false
  },
  {
    id: 2,
    name: 'Media Lab',
    description: 'Repudiandae mutat discere prodesset curae qualisque at mea duis ferri.',
    characteristics: 'Cursus duo interesset ad semper dolor causae laudem quem tempus. Fuisset ac invenire oratio auctor eos indoctum tibique.',
    slug: 'media-lab',
    default_places: 2,
    disabled: true
  }
];

export default spaces;
