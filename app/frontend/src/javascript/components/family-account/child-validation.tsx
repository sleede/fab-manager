import { useState, useEffect } from 'react';
import * as React from 'react';
import Switch from 'react-switch';
import _ from 'lodash';
import { useTranslation } from 'react-i18next';
import { Child } from '../../models/child';
import ChildAPI from '../../api/child';
import { TDateISO } from '../../typings/date-iso';

interface ChildValidationProps {
  child: Child
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component allows to configure boolean value for a setting.
 */
export const ChildValidation: React.FC<ChildValidationProps> = ({ child, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [value, setValue] = useState<boolean>(!!(child?.validated_at));

  useEffect(() => {
    setValue(!!(child?.validated_at));
  }, [child]);

  /**
   * Callback triggered when the 'switch' is changed.
   */
  const handleChanged = (_value: boolean) => {
    setValue(_value);
    const _child = _.clone(child);
    if (_value) {
      _child.validated_at = new Date().toISOString() as TDateISO;
    } else {
      _child.validated_at = null;
    }
    ChildAPI.validate(_child)
      .then(() => {
        onSuccess(t(`app.admin.child_validation.${_value ? 'validate' : 'invalidate'}_child_success`));
      }).catch(err => {
        setValue(!_value);
        onError(t(`app.admin.child_validation.${_value ? 'validate' : 'invalidate'}_child_error`) + err);
      });
  };

  return (
    <div className="child-validation">
      <label htmlFor="child-validation-switch">{t('app.admin.child_validation.validate_child')}</label>
      <Switch checked={value} id="child-validation-switch" onChange={handleChanged} className="switch"></Switch>
    </div>
  );
};
