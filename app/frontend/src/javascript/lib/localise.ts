import { IFablab } from '../models/fablab';
import zxcvbnCommonPackage from '@zxcvbn-ts/language-common';
import zxcvbnEnPackage from '@zxcvbn-ts/language-en';
import zxcvbnDePackage from '@zxcvbn-ts/language-de';
import zxcvbnEsPackage from '@zxcvbn-ts/language-es-es';
import zxcvbnFrPackage from '@zxcvbn-ts/language-fr';
import zxcvbnPtPackage from '@zxcvbn-ts/language-pt-br';

declare let Fablab: IFablab;
/**
 * Localization specific handlers
 */
export default class LocaliseLib {
  /**
   * Bind the dictionnaries for the zxcvbn lib, to the current locale configuration of the app (APP_LOCALE).
   */
  static zxcvbnDictionnaries = () => {
    switch (Fablab.locale) {
      case 'de':
        return {
          ...zxcvbnCommonPackage.dictionary,
          ...zxcvbnDePackage.dictionary
        };
      case 'es':
        return {
          ...zxcvbnCommonPackage.dictionary,
          ...zxcvbnEsPackage.dictionary
        };
      case 'fr':
        return {
          ...zxcvbnCommonPackage.dictionary,
          ...zxcvbnFrPackage.dictionary
        };
      case 'pt':
        return {
          ...zxcvbnCommonPackage.dictionary,
          ...zxcvbnPtPackage.dictionary
        };
      default:
        return {
          ...zxcvbnCommonPackage.dictionary,
          ...zxcvbnEnPackage.dictionary
        };
    }
  };
}
