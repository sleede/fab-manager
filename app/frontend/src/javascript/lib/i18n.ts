import i18n from 'i18next';
import ICU from 'i18next-icu';
import HttpApi from 'i18next-http-backend';
import { initReactI18next } from 'react-i18next';

declare var Fablab: any;

i18n
  .use(ICU)
  .use(HttpApi)
  .use(initReactI18next)
  .init({
    lng: Fablab.locale,
    fallbackLng: 'en',
    ns: ['admin', 'logged', 'public', 'shared'],
    defaultNS: 'shared',
    backend: {
      loadPath: '/api/translations/{{lng}}/app.{{ns}}'
    }
  });

export default i18n;
