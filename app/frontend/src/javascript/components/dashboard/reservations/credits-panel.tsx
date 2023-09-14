import { ReactNode, useEffect, useState } from 'react';
import * as React from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Loader } from '../../base/loader';
import { useTranslation } from 'react-i18next';
import { Credit, CreditableType } from '../../../models/credit';
import CreditAPI from '../../../api/credit';
import { HtmlTranslate } from '../../base/html-translate';
import { User } from '../../../models/user';

interface CreditsPanelProps {
  userId: number,
  currentUser?: User,
  onError: (message: string) => void,
  reservableType: CreditableType
}

/**
 * List all available credits for the given user and the given resource
 */
const CreditsPanel: React.FC<CreditsPanelProps> = ({ userId, currentUser = null, onError, reservableType }) => {
  const { t } = useTranslation('logged');

  const [credits, setCredits] = useState<Array<Credit>>([]);

  useEffect(() => {
    CreditAPI.userResource(userId, reservableType)
      .then(res => setCredits(res))
      .catch(error => onError(error));
  }, []);

  /**
   * Compute the remaining hours for the given credit
   */
  const remainingHours = (credit: Credit): number => {
    return credit.hours - credit.hours_used;
  };

  /**
   * Display a placeholder when there's no credits to display
   */
  const noCredits = (currentUser: User): ReactNode => {
    return (
      <div className="fab-alert fab-alert--warning">{t(`app.logged.dashboard.reservations_dashboard.${translationKeyPrefix(currentUser)}.no_credits`) /* eslint-disable-line fabmanager/scoped-translation */ }</div>
    );
  };

  /**
   * returns true if there is a currentUser and current user is manager or admin
   */
  const currentUserIsAdminOrManager = (currentUser: User): boolean => {
    return currentUser && (currentUser.role === 'admin' || currentUser.role === 'manager');
  };

  /**
   * returns translation key prefix
   */
  const translationKeyPrefix = (currentUser: User): string => {
    return currentUserIsAdminOrManager(currentUser) ? 'credits_panel_as_admin' : 'credits_panel';
  };

  return (
    <FabPanel className="credits-panel">
      <p className="title">{t(`app.logged.dashboard.reservations_dashboard.${translationKeyPrefix(currentUser)}.title`) /* eslint-disable-line fabmanager/scoped-translation */}</p>
      {credits.length !== 0 && !currentUserIsAdminOrManager(currentUser) &&
        <div className="fab-alert fab-alert--warning">
          {t('app.logged.dashboard.reservations_dashboard.credits_panel.info')}
        </div>
      }

      <div className="credits-list">
        {credits.map(c => <div key={c.id} className="credits-list-item">
          <p className="title">{c.creditable.name}</p>
          <p>
            <HtmlTranslate trKey={`app.logged.dashboard.reservations_dashboard.${translationKeyPrefix(currentUser)}.remaining_credits_html` /* eslint-disable-line fabmanager/scoped-translation */} options={{ REMAINING: remainingHours(c) }} /><br />
            {(c.hours_used && c.hours_used > 0) &&
              <HtmlTranslate trKey={`app.logged.dashboard.reservations_dashboard.${translationKeyPrefix(currentUser)}.used_credits_html` /* eslint-disable-line fabmanager/scoped-translation */} options={{ USED: c.hours_used }} />
            }
          </p>
        </div>)}
      </div>
      {credits.length === 0 && noCredits(currentUser)}
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
