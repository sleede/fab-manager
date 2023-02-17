import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MachinesSettings } from '../../../../app/frontend/src/javascript/components/machines/machines-settings';
import { tiptapEvent } from '../../__lib__/tiptap';

// Machines Settings
describe('Machines Settings', () => {
  test('should render the correct form', async () => {
    const onError = jest.fn();
    const onSuccess = jest.fn();

    render(<MachinesSettings onError={onError} onSuccess={onSuccess}/>);
    await waitFor(() => screen.getByTestId('editorial-block-form'));
    expect(screen.getByLabelText(/app.admin.editorial_block_form.content/)).toBeDefined();
    expect(screen.getByLabelText(/app.admin.editorial_block_form.cta_label/)).toBeDefined();
    expect(screen.getByLabelText(/app.admin.editorial_block_form.cta_url/)).toBeDefined();
  });

  test('create a banner', async () => {
    const onError = jest.fn();
    const onSuccess = jest.fn();
    const beforeSubmit = jest.fn();

    render(<MachinesSettings onError={onError} onSuccess={onSuccess} beforeSubmit={beforeSubmit}/>);
    await waitFor(() => screen.getByTestId('editorial-block-form'));
    await tiptapEvent.type(screen.getByLabelText(/app.admin.editorial_block_form.content/), 'Lorem ipsum dolor sit amet');
    fireEvent.change(screen.getByLabelText(/app.admin.editorial_block_form.cta_label/), { target: { value: 'Button Label 1' } });
    fireEvent.change(screen.getByLabelText(/app.admin.editorial_block_form.cta_url/), { target: { value: 'https://www.sleede.com/' } });
    fireEvent.click(screen.getByRole('button', { name: /app.admin.machines_settings.save/ }));
    const expected = {
      machines_banner_active: true,
      machines_banner_text: '<p>Lorem ipsum dolor sit amet</p>',
      machines_banner_cta_active: true,
      machines_banner_cta_label: 'Button Label 1',
      machines_banner_cta_url: 'https://www.sleede.com/'
    };
    await waitFor(() => expect(onSuccess).toHaveBeenCalledTimes(1));
    expect(beforeSubmit).toHaveBeenCalledWith(expect.objectContaining(expected));
  });
});
