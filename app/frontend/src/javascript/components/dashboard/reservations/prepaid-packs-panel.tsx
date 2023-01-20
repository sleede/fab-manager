import { FabPanel } from '../../base/fab-panel';
import { Loader } from '../../base/loader';
import { useTranslation } from 'react-i18next';
import { useEffect, useState } from 'react';
import { UserPack } from '../../../models/user-pack';
import UserPackAPI from '../../../api/user-pack';
import FormatLib from '../../../lib/format';
import SettingAPI from '../../../api/setting';

interface PrepaidPacksPanelProps {
  userId: number,
  onError: (message: string) => void
}

/**
 * List all available prepaid packs for the given user
 */
const PrepaidPacksPanel: React.FC<PrepaidPacksPanelProps> = ({ userId, onError }) => {
  const { t } = useTranslation('logged');

  const [packs, setPacks] = useState<Array<UserPack>>([]);
  const [threshold, setThreshold] = useState<number>(null);

  useEffect(() => {
    UserPackAPI.index({ user_id: userId })
      .then(res => setPacks(res))
      .catch(error => onError(error));
    SettingAPI.get('renew_pack_threshold')
      .then(data => setThreshold(parseFloat(data.value)))
      .catch(error => onError(error));
  }, []);

  /**
   * Check if the provided pack has a remaining amount of hours under the defined threshold
   */
  const isLow = (pack: UserPack): boolean => {
    if (threshold < 1) {
      return pack.prepaid_pack.minutes - pack.minutes_used <= pack.prepaid_pack.minutes * threshold;
    }
    return pack.prepaid_pack.minutes - pack.minutes_used <= threshold * 60;
  };

  return (
    <FabPanel className='prepaid-packs-panel'>
      <p className="title">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.title')}</p>

      {packs.map(pack => (
        <div className={`prepaid-packs ${isLow(pack) ? 'is-low' : ''}`} key={pack.id}>
          <div className='prepaid-packs-list'>
            <span className="prepaid-packs-list-label name">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.name')}</span>
            <span className="prepaid-packs-list-label end">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.end')}</span>
            <span className="prepaid-packs-list-label countdown">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.countdown')}</span>

            <div className='prepaid-packs-list-item'>
              <p className='name'>{pack.prepaid_pack.priceable.name}</p>
              {FormatLib.date(pack.expires_at) && <p className="end">{FormatLib.date(pack.expires_at)}</p>}
              <p className="countdown"><span>{pack.minutes_used / 60}H</span> / {pack.prepaid_pack.minutes / 60}H</p>
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
      ))}

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
