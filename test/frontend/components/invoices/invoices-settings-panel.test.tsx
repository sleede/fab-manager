import { InvoicesSettingsPanel } from '../../../../app/frontend/src/javascript/components/invoices/invoices-settings-panel';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

describe('InvoicesSettingsPanel', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('render InvoicesSettingsPanel', async () => {
    render(<InvoicesSettingsPanel onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getByLabelText(/app.admin.invoices_settings_panel.disable_invoices_zero_label/)).toBeInTheDocument();
    });
    expect(screen.getAllByLabelText(/app.admin.invoices_settings_panel.prefix/)).toHaveLength(2);
    expect(screen.getByRole('heading', { name: /app.admin.invoices_settings_panel.filename/ })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /app.admin.invoices_settings_panel.schedule_filename/ })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.invoices_settings_panel.save/ })).toBeInTheDocument();
  });

  test('update filename example', async () => {
    render(<InvoicesSettingsPanel onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getAllByLabelText(/app.admin.invoices_settings_panel.prefix/)).toHaveLength(2);
    });
    fireEvent.change(screen.getByLabelText(/app.admin.invoices_settings_panel.prefix/, { selector: 'input#invoice_prefix' }), { target: { value: 'Test Example' } });
    expect(screen.getByRole('heading', { name: /app.admin.invoices_settings_panel.filename/ }).parentNode.querySelector('.example > .content'))
      .toHaveTextContent(/^Test Example/);
  });

  test('update schedule filename example', async () => {
    render(<InvoicesSettingsPanel onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => {
      expect(screen.getAllByLabelText(/app.admin.invoices_settings_panel.prefix/)).toHaveLength(2);
    });
    fireEvent.change(screen.getByLabelText(/app.admin.invoices_settings_panel.prefix/, { selector: 'input#payment_schedule_prefix' }), { target: { value: 'Schedule Test' } });
    expect(screen.getByRole('heading', { name: /app.admin.invoices_settings_panel.schedule_filename/ }).parentNode.querySelector('.example > .content'))
      .toHaveTextContent(/^Schedule Test/);
  });
});
