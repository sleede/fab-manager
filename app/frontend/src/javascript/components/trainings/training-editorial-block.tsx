import { useEffect, useState } from 'react';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { EditorialBlock } from '../editorial-block/editorial-block';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { SettingValue, trainingsSettings } from '../../models/setting';

declare const Application: IApplication;

interface TrainingEditorialBlockProps {
  onError: (message: string) => void
}

/**
 * This component displays to Users the editorial block (banner) associated to trainings.
 */
export const TrainingEditorialBlock: React.FC<TrainingEditorialBlockProps> = ({ onError }) => {
  // Store Banner retrieved from API
  const [banner, setBanner] = useState<Record<string, SettingValue>>({});

  // Retrieve the settings related to the Trainings Banner from the API
  useEffect(() => {
    SettingAPI.query(trainingsSettings)
      .then(settings => {
        setBanner({ ...SettingLib.bulkMapToObject(settings) });
      })
      .catch(onError);
  }, []);

  return (
    <>
      {banner.trainings_banner_active &&
        <EditorialBlock
          text={banner.trainings_banner_text}
          cta={banner.trainings_banner_cta_active && banner.trainings_banner_cta_label}
          url={banner.trainings_banner_cta_active && banner.trainings_banner_cta_url} />
      }
    </>
  );
};

const TrainingEditorialBlockWrapper: React.FC<TrainingEditorialBlockProps> = (props) => {
  return (
    <Loader>
      <TrainingEditorialBlock {...props} />
    </Loader>
  );
};

Application.Components.component('trainingEditorialBlock', react2angular(TrainingEditorialBlockWrapper, ['onError']));
