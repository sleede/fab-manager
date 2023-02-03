import { FabPanel } from '../../base/fab-panel';
import { Loader } from '../../base/loader';
import { useTranslation } from 'react-i18next';
import { useEffect, useState } from 'react';
import { UserPack } from '../../../models/user-pack';
import UserPackAPI from '../../../api/user-pack';
import FormatLib from '../../../lib/format';
import SettingAPI from '../../../api/setting';
import { Machine } from '../../../models/machine';
import MachineAPI from '../../../api/machine';
import { SubmitHandler, useForm } from 'react-hook-form';
import { FabButton } from '../../base/fab-button';
import { FormSelect } from '../../form/form-select';
import { SelectOption } from '../../../models/select';
import { ProposePacksModal } from '../../prepaid-packs/propose-packs-modal';
import * as React from 'react';
import { User } from '../../../models/user';
import PrepaidPackAPI from '../../../api/prepaid-pack';
import { PrepaidPack } from '../../../models/prepaid-pack';

interface PrepaidPacksPanelProps {
  user: User,
  onError: (message: string) => void
}

/**
 * List all available prepaid packs for the given user
 */
const PrepaidPacksPanel: React.FC<PrepaidPacksPanelProps> = ({ user, onError }) => {
  const { t } = useTranslation('logged');

  const [machines, setMachines] = useState<Array<Machine>>([]);
  const [packs, setPacks] = useState<Array<PrepaidPack>>([]);
  const [userPacks, setUserPacks] = useState<Array<UserPack>>([]);
  const [threshold, setThreshold] = useState<number>(null);
  const [selectedMachine, setSelectedMachine] = useState<Machine>(null);
  const [packsModal, setPacksModal] = useState<boolean>(false);
  const [packsForSubscribers, setPacksForSubscribers] = useState<boolean>(false);

  const { handleSubmit, control, formState } = useForm<{ machine_id: number }>();

  useEffect(() => {
    UserPackAPI.index({ user_id: user.id })
      .then(setUserPacks)
      .catch(onError);
    SettingAPI.get('renew_pack_threshold')
      .then(data => setThreshold(parseFloat(data.value)))
      .catch(onError);
    MachineAPI.index({ disabled: false })
      .then(setMachines)
      .catch(onError);
    PrepaidPackAPI.index({ disabled: false, group_id: user.group_id, priceable_type: 'Machine' })
      .then(setPacks)
      .catch(onError);
    SettingAPI.get('pack_only_for_subscription')
      .then(data => setPacksForSubscribers(data.value === 'true'))
      .catch(onError);
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

  /**
   * Callback triggered when the user clicks on "buy a pack"
   */
  const onBuyPack: SubmitHandler<{ machine_id: number }> = (data) => {
    const machine = machines.find(m => m.id === data.machine_id);
    setSelectedMachine(machine);
    togglePacksModal();
  };

  /**
   * Open/closes the buy pack modal
   */
  const togglePacksModal = () => {
    setPacksModal(!packsModal);
  };

  /**
   * Build the options for the select dropdown, for the given list of machines
   */
  const buildMachinesOptions = (machines: Array<Machine>): Array<SelectOption<number>> => {
    const packMachinesId = packs.map(p => p.priceable_id);
    return machines.filter(m => packMachinesId.includes(m.id)).map(m => {
      return { label: m.name, value: m.id };
    });
  };

  /**
   * Check if the user can buy a pack
   */
  const canBuyPacks = (): boolean => {
    return (packs.length > 0 && (!packsForSubscribers || (packsForSubscribers && user.subscribed_plan != null)));
  };

  /**
   * Callback triggered when a prepaid pack was successfully bought: refresh the list of packs for the user
   */
  const onPackBoughtSuccess = () => {
    togglePacksModal();
    UserPackAPI.index({ user_id: user.id })
      .then(setUserPacks)
      .catch(onError);
  };

  return (
    <FabPanel className='prepaid-packs-panel'>
      <p className="title">{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.title')}</p>

      {userPacks.map(pack => (
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
          { /* usage history is not saved for now
          <div className="prepaid-packs-list is-history">
            <span className='prepaid-packs-list-label'>{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.history')}</span>

            <div className='prepaid-packs-list-item'>
              <p className='name'>00{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.consumed_hours')}</p>
              <p className="date">00/00/00</p>
            </div>
          </div>
          */ }
        </div>
      ))}

      {canBuyPacks() && <div className='prepaid-packs-cta'>
        <p>{t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.cta_info')}</p>
        <form onSubmit={handleSubmit(onBuyPack)}>
          <FormSelect options={buildMachinesOptions(machines)} control={control} id="machine_id" rules={{ required: true }} formState={formState} label={t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.select_machine')} />
          <FabButton className='is-black' type="submit">
            {t('app.logged.dashboard.reservations_dashboard.prepaid_packs_panel.cta_button')}
          </FabButton>
        </form>
        {selectedMachine && packsModal &&
          <ProposePacksModal isOpen={packsModal}
                             toggleModal={togglePacksModal}
                             item={selectedMachine}
                             itemType='Machine'
                             customer={user}
                             operator={user}
                             onError={onError}
                             onDecline={togglePacksModal}
                             onSuccess={onPackBoughtSuccess} />}
      </div>}

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
