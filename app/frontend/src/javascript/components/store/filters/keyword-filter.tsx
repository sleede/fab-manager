import { useEffect, useState } from 'react';
import * as React from 'react';
import { FabButton } from '../../base/fab-button';
import { AccordionItem } from '../../base/accordion-item';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';

interface KeywordFilterProps {
  onApplyFilters: (keywork: string) => void,
  currentFilters?: string,
  openDefault?: boolean,
  instantUpdate?: boolean,
}

/**
 * Component to filter the products list by keyword or product reference
 */
export const KeywordFilter: React.FC<KeywordFilterProps> = ({ onApplyFilters, currentFilters = '', openDefault = false, instantUpdate = false }) => {
  const { t } = useTranslation('admin');

  const [openedAccordion, setOpenedAccordion] = useState<boolean>(openDefault);
  const [keyword, setKeyword] = useState<string>(currentFilters || '');

  useEffect(() => {
    if (!_.isEqual(currentFilters, keyword)) {
      setKeyword(currentFilters);
    }
  }, [currentFilters]);

  /**
   * Open/close the accordion item
   */
  const handleAccordion = (id, state: boolean) => {
    setOpenedAccordion(state);
  };

  /**
   * Callback triggered when the user types anything in the input
   */
  const handleKeywordTyping = (evt: React.ChangeEvent<HTMLInputElement>) => {
    setKeyword(evt.target.value);

    if (instantUpdate) {
      onApplyFilters(evt.target.value);
    }
  };

  return (
    <>
      <AccordionItem id={2}
                     isOpen={openedAccordion}
                     onChange={handleAccordion}
                     label={t('app.admin.store.keyword_filter.filter_keywords_reference')}
      >
        <div className="content">
          <div className="group">
            <input type="text" onChange={event => handleKeywordTyping(event)} value={keyword} />
            <FabButton onClick={() => onApplyFilters(keyword || undefined)} className="is-secondary">{t('app.admin.store.keyword_filter.filter_apply')}</FabButton>
          </div>
        </div>
      </AccordionItem>
    </>
  );
};
