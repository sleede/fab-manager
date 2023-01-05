import * as React from 'react';
import { useTranslation } from 'react-i18next';

interface HtmlTranslateProps {
  trKey: string,
  options?: Record<string, string|number>
}

/**
 * This component renders a translation with some HTML content.
 */
export const HtmlTranslate: React.FC<HtmlTranslateProps> = ({ trKey, options }) => {
  const { t } = useTranslation(trKey?.split('.')[1]);

  return (
    <span dangerouslySetInnerHTML={{ __html: t(trKey, options) }} />
  );
};
