import React, { ReactNode, useEffect, useState } from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Loader } from '../../base/loader';
import { useTranslation } from 'react-i18next';
import { Credit, CreditableType } from '../../../models/credit';
import CreditAPI from '../../../api/credit';
import { HtmlTranslate } from '../../base/html-translate';

interface CreditsPanelProps {
  userId: number,
  onError: (message: string) => void,
  reservableType: CreditableType
}

/**
 * List all available credits for the given user and the given resource
 */
const CreditsPanel: React.FC<CreditsPanelProps> = ({ userId, onError, reservableType }) => {
  const { t } = useTranslation('logged');

  const [credits, setCredits] = useState<Array<Credit>>([]);

  useEffect(() => {
    CreditAPI.userResource(userId, reservableType)
      .then(res => setCredits(res))
      .catch(error => onError(error));
  }, []);

  /**
   * Compute the remainings hours for the given credit
   */
  const remainingHours = (credit: Credit): number => {
    return credit.hours - credit.hours_used;
  };

  /**
   * Display a placeholder when there's no credits to display
   */
  const noCredits = (): ReactNode => {
    return (
      <li className="no-credits">{t('app.logged.dashboard.reservations.credits_panel.no_credits')}</li>
    );
  };

  /**
   * Panel title
   */
  const header = (): ReactNode => {
    return (
      <div>
        {t(`app.logged.dashboard.reservations.credits_panel.title_${reservableType}`)}
      </div>
    );
  };

  return (
    <FabPanel className="credits-panel" header={header()}>
      <ul>
      {credits.map(c => <li key={c.id}>
        <HtmlTranslate trKey="app.logged.dashboard.reservations.credits_panel.reamaining_credits_html" options={{ NAME: c.creditable.name, REMAINING: remainingHours(c), USED: c.hours_used }} />
      </li>)}
      {credits.length === 0 && noCredits()}
      </ul>
    </FabPanel>
  );
};

const CreditsPanelWrapper: React.FC<CreditsPanelProps> = (props) => {
  return (
    <Loader>
      <CreditsPanel {...props} />
    </Loader>
  );
};

export { CreditsPanelWrapper as CreditsPanel };
