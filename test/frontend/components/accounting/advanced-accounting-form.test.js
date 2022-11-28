import React from 'react';
import { AdvancedAccountingForm } from 'components/accounting/advanced-accounting-form';
import { render, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { rest } from 'msw';
import { setupServer } from 'msw/node';
import { server as apiServer } from '../../__setup__/server';

describe('AdvancedAccountingForm', () => {
  const register = jest.fn();
  const onError = jest.fn();

  test('render AdvancedAccountingForm', async () => {
    render(<AdvancedAccountingForm register={register} onError={onError} />);
    await waitFor(() => screen.getByRole('heading', { name: /app.admin.advanced_accounting_form.title/ }));
    // advanced accounting is enabled in fixtures
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.code/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.analytical_section/)).toBeInTheDocument();
  });

  test('render AdvancedAccountingForm when disabled', async () => {
    // set up a custom API answer for this test
    apiServer.close();
    const server = setupServer(
      rest.get('/api/settings/advanced_accounting', (req, res, ctx) => {
        return res(ctx.json({ setting: { name: 'advanced_accounting', value: 'false' } }));
      })
    );
    server.listen();

    // run the test
    render(<AdvancedAccountingForm register={register} onError={onError} />);
    await waitFor(() => document.querySelector('.advanced-accounting-form'));
    // advanced accounting is enabled in fixtures
    expect(screen.queryByLabelText(/app.admin.advanced_accounting_form.code/)).toBeNull();
    expect(screen.queryByLabelText(/app.admin.advanced_accounting_form.analytical_section/)).toBeNull();

    // remove the custom API
    server.resetHandlers();
    server.close();
  });
});
