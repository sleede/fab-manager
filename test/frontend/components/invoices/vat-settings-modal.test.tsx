import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { VatSettingsModal } from '../../../../app/frontend/src/javascript/components/invoices/vat-settings-modal';

describe('VatSettingsModal', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();
  const toggleModal = jest.fn();

  test('render VatSettingsModal', async () => {
    render(<VatSettingsModal isOpen={true} toggleModal={toggleModal} onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getByLabelText(/app.admin.vat_settings_modal.enable_VAT/)).toBeChecked();
      expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_name/)).toHaveValue('TVA');
      expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate/)).toHaveValue(20);
    });
    // the following buttons must be selected with hidden:true because of an issue in react-modal in conjunction with react2angular;
    // this will be fixed when the full migration to react is over.
    expect(screen.getByRole('button', { name: /app.admin.vat_settings_modal.advanced/, hidden: true })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.vat_settings_modal.save/, hidden: true })).toBeInTheDocument();
  });

  test('show advanced rates', async () => {
    render(<VatSettingsModal isOpen={true} toggleModal={toggleModal} onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getByLabelText(/app.admin.vat_settings_modal.enable_VAT/)).toBeChecked();
    });
    fireEvent.click(screen.getByRole('button', { name: /app.admin.vat_settings_modal.advanced/, hidden: true }));
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_product/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_event/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_machine/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_subscription/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_space/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.vat_settings_modal.VAT_rate_training/)).toBeInTheDocument();
  });

  test('show history', async () => {
    render(<VatSettingsModal isOpen={true} toggleModal={toggleModal} onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getByLabelText(/app.admin.vat_settings_modal.enable_VAT/)).toBeChecked();
    });
    fireEvent.click(screen.getByRole('button', { name: /app.admin.vat_settings_modal.show_history/, hidden: true }));
    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /app.admin.setting_history_modal.title/, hidden: true })).toBeInTheDocument();
    });
  });
});
