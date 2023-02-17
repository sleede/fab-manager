import * as React from 'react';
import { useTranslation } from 'react-i18next';

interface HtmlTranslateProps {
  trKey: string,
  className?: string,
  options?: Record<string, string|number>
}

/**
 * This component renders a translation with some HTML content.
 */
export const HtmlTranslate: React.FC<HtmlTranslateProps> = ({ trKey, className, options }) => {
  const { t } = useTranslation(trKey?.split('.')[1]);

  /* eslint-disable fabmanager/component-class-named-as-component */
  return (
    <span className={className || ''} dangerouslySetInnerHTML={{ __html: t(trKey, options) }} />
  );
  /* eslint-enable fabmanager/component-class-named-as-component */
};
