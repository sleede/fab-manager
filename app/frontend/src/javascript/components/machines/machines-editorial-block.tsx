import { useEffect, useState } from 'react';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { EditorialBlock } from '../editorial-block/editorial-block';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { SettingValue, machinesSettings } from '../../models/setting';

declare const Application: IApplication;

interface MachinesEditorialBlockProps {
  onError: (message: string) => void
}

/**
 * This component displays to Users the editorial block (banner) associated to machines.
 */
export const MachinesEditorialBlock: React.FC<MachinesEditorialBlockProps> = ({ onError }) => {
  // Store Banner retrieved from API
  const [banner, setBanner] = useState<Record<string, SettingValue>>({});

  // Retrieve the settings related to the Machines Banner from the API
  useEffect(() => {
    SettingAPI.query(machinesSettings)
      .then(settings => {
        setBanner({ ...SettingLib.bulkMapToObject(settings) });
      })
      .catch(onError);
  }, []);

  return (
    <>
      {banner.machines_banner_active &&
        <EditorialBlock
          text={banner.machines_banner_text}
          cta={banner.machines_banner_cta_active && banner.machines_banner_cta_label}
          url={banner.machines_banner_cta_active && banner.machines_banner_cta_url} />
      }
    </>
  );
};

const MachinesEditorialBlockWrapper: React.FC<MachinesEditorialBlockProps> = (props) => {
  return (
    <Loader>
      <MachinesEditorialBlock {...props} />
    </Loader>
  );
};

Application.Components.component('machinesEditorialBlock', react2angular(MachinesEditorialBlockWrapper, ['onError']));
