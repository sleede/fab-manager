import React from 'react';
import { AccountingCodesSettings } from 'components/accounting/accounting-codes-settings';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

describe('AccountingCodesSettings', () => {
  const onSuccess = jest.fn(message => {});
  const onError = jest.fn(e => {});

  test('render AccountingCodesSettings', async () => {
    render(<AccountingCodesSettings onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('heading', { name: /app.admin.accounting_codes_settings.advanced_accounting/ }));
    expect(screen.getByLabelText(/app.admin.accounting_codes_settings.enable_advanced/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.accounting_codes_settings.journal_code/)).toBeInTheDocument();
    expect(screen.getAllByLabelText(/app.admin.accounting_codes_settings.code/)).toHaveLength(13);
    expect(screen.getAllByLabelText(/app.admin.accounting_codes_settings.label/)).toHaveLength(13);
    expect(screen.getByRole('button', { name: /app.admin.accounting_codes_settings.save/ })).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: /app.admin.accounting_codes_settings.save/ }));
    await waitFor(() => {
      expect(onSuccess).toHaveBeenCalledWith('app.admin.accounting_codes_settings.update_success');
    });
  });
});
