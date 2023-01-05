import { FabPanel } from '../../base/fab-panel';
import { Loader } from '../../base/loader';
import { useTranslation } from 'react-i18next';

interface PrepaidPacksPanelProps {
  userId: number,
  onError: (message: string) => void
}

/**
 * List all available prepaid packs for the given user
 */
const PrepaidPacksPanel: React.FC<PrepaidPacksPanelProps> = () => {
  const { t } = useTranslation('logged');

  return (
    <FabPanel className='prepaid-packs-panel'>
      <p className="title">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.title')}</p>

      {/* map */}
      <div className='prepaid-packs is-low'>
        <div className='prepaid-packs-list'>
          <span className="prepaid-packs-list-label name">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.name')}</span>
          <span className="prepaid-packs-list-label end">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.end')}</span>
          <span className="prepaid-packs-list-label countdown">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.countdown')}</span>

          <div className='prepaid-packs-list-item'>
            <p className='name'>Pack name</p>
            <p className='end'>00/00/0000</p>
            <p className="countdown"><span>00H</span> / 00H</p>
          </div>
        </div>

        <div className="prepaid-packs-list is-history">
          <span className='prepaid-packs-list-label'>{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.history')}</span>

          <div className='prepaid-packs-list-item'>
            <p className='name'>00{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.consumed_hours')}</p>
            <p className="date">00/00/00</p>
          </div>
        </div>
      </div>

      <div className='prepaid-packs-cta'>
        <p>{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.cta_info')}</p>
        <button className='fab-button is-black'>{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.cta_button')}</button>
      </div>

    </FabPanel>
  );
};

const PrepaidPacksPanelWrapper: React.FC<PrepaidPacksPanelProps> = (props) => {
  return (
    <Loader>
      <PrepaidPacksPanel {...props} />
    </Loader>
  );
};

export { PrepaidPacksPanelWrapper as PrepaidPacksPanel };
