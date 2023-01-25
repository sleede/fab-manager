import { render, screen } from '@testing-library/react';
import { EditorialBlock } from '../../../../app/frontend/src/javascript/components/editorial-block/editorial-block';
import { settings } from '../../__fixtures__/settings';

// Editorial Block
describe('Editorial Block', () => {
  test('should render the correct block', async () => {
    const machinesBannerText = settings.find((setting) => setting.name === 'machines_banner_text').value;
    const machinesBannerCtaActive = settings.find((setting) => setting.name === 'machines_banner_cta_active').value;
    const machinesBannerCtaLabel = settings.find((setting) => setting.name === 'machines_banner_cta_label').value;
    const machinesBannerCtaUrl = settings.find((setting) => setting.name === 'machines_banner_cta_url').value;

    render(<EditorialBlock
      text={machinesBannerText}
      cta={machinesBannerCtaActive && machinesBannerCtaLabel}
      url={machinesBannerCtaActive && machinesBannerCtaUrl} />);

    expect(screen.getByText('Test for machines Banner Content')).toBeDefined();
    expect(screen.getByText('Test for machines Banner Button')).toBeDefined();
  });
});
