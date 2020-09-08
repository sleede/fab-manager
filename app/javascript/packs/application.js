import 'core-js/stable';
import 'regenerator-runtime/runtime';

import '../stylesheets/application.scss.erb';

const images = require.context('../images', true);
const imagePath = (name) => images(name, true);
