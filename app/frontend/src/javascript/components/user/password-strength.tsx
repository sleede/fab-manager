import * as React from 'react';
import { useEffect, useState } from 'react';
import { zxcvbn, zxcvbnOptions } from '@zxcvbn-ts/core';
import zxcvbnCommonPackage from '@zxcvbn-ts/language-common';
import { debounce as _debounce } from 'lodash';
import LocaliseLib from '../../lib/localise';
import type { ZxcvbnResult } from '@zxcvbn-ts/core/src/types';
import { useTranslation } from 'react-i18next';

interface PasswordStrengthProps {
  password?: string,
}

const SPECIAL_CHARS = ['!', '#', '$', '%', '&', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', ']', '^', '_', '{', '|', '}', '~', "'", '`', '"'];

/**
 * Shows a visual indicator of the password strength
 */
export const PasswordStrength: React.FC<PasswordStrengthProps> = ({ password }) => {
  const { t } = useTranslation('shared');

  const [strength, setStrength] = useState<ZxcvbnResult>(null);
  const [hasRequirements, setHasRequirements] = useState<boolean>(false);

  /*
   * zxcvbn library options
   * @see https://zxcvbn-ts.github.io/zxcvbn/guide/getting-started/
   */
  const options = {
    translations: null,
    graphs: zxcvbnCommonPackage.adjacencyGraphs,
    dictionary: LocaliseLib.zxcvbnDictionnaries()
  };
  zxcvbnOptions.setOptions(options);

  /**
   * Compute the strength of the given password and update the result in memory
   */
  const updateStrength = () => {
    if (typeof password === 'string') {
      if (checkRequirements()) {
        setHasRequirements(true);
        const result = zxcvbn(password);
        setStrength(result);
      } else {
        setHasRequirements(false);
      }
    }
  };

  /**
   * Check if the provided password meet the minimal requirements
   */
  const checkRequirements = (): boolean => {
    if (typeof password === 'string') {
      const chars = password.split('');
      return (chars.some(c => SPECIAL_CHARS.includes(c)) &&
        !!password.match(/[A-Z]/) &&
        !!password.match(/[a-z]/) &&
        !!password.match(/[0-9]/) &&
        password.length >= 12);
    }
  };

  useEffect(_debounce(updateStrength, 500), [password]);

  return (
    <div className="password-strength">
      {password && !hasRequirements && <>
        <span className="requirements-error">{t('app.shared.password_strength.not_in_requirements')}</span>
      </>}
      {hasRequirements && strength && <>
        <div className={`strength-bar strength-${strength.score}`} />
        <span>{t(`app.shared.password_strength.${strength.score}`)}</span>
      </>}
    </div>
  );
};
