import React from 'react';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { PlanForm } from 'components/plans/plan-form';
import plans from '../../__fixtures__/plans';

describe('PlanForm', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('render create PlanForm', async () => {
    render(<PlanForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_form.group/ }));
    expect(screen.getByLabelText(/app.admin.plan_form.name/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.transversal/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.group/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.category/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.subscription_price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.visual_prominence/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.rolling_subscription/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.monthly_payment/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.description/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.information_sheet/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.disabled/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.number_of_periods/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.period/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.partner_plan/)).toBeInTheDocument();
    expect(screen.queryByTestId('plan-pricing-form')).toBeNull();
    expect(screen.getByRole('button', { name: /app.admin.plan_form.ACTION_plan/ })).toBeInTheDocument();
  });

  test('render update PlanForm with partner', async () => {
    const plan = plans[1];
    render(<PlanForm action="update" plan={plan} onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_pricing_form.copy_prices_from/ }));
    expect(screen.getByLabelText(/app.admin.plan_form.name/)).toBeInTheDocument();
    expect(screen.queryByLabelText(/app.admin.plan_form.transversal/)).toBeNull();
    expect(screen.getByLabelText(/app.admin.plan_form.group/)).toBeDisabled();
    expect(screen.getByLabelText(/app.admin.plan_form.category/)).toBeInTheDocument();
    expect(screen.getByText(/app.admin.plan_form.edit_amount_info/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.subscription_price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.visual_prominence/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.rolling_subscription/)).toBeDisabled();
    expect(screen.getByLabelText(/app.admin.plan_form.monthly_payment/)).toBeDisabled();
    expect(screen.getByLabelText(/app.admin.plan_form.description/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.information_sheet/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.disabled/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.number_of_periods/)).toBeDisabled();
    expect(screen.getByLabelText(/app.admin.plan_form.period/)).toBeDisabled();
    expect(screen.getByLabelText(/app.admin.plan_form.partner_plan/)).toBeDisabled();
    expect(screen.getByRole('button', { name: /app.admin.plan_form.new_user/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.plan_form.notified_partner/)).toBeInTheDocument();
    expect(screen.getByText(/app.admin.plan_form.alert_partner_notification/)).toBeInTheDocument();
    expect(screen.getByTestId('plan-pricing-form')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.plan_form.ACTION_plan/ })).toBeInTheDocument();
  });

  test('selecting transversal plan disables group select', async () => {
    render(<PlanForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_form.group/ }));
    fireEvent.click(screen.getByRole('switch', { name: /app.admin.plan_form.transversal/ }));
    expect(screen.queryByRole('combobox', { name: /app.admin.plan_form.group/ })).toBeNull();
  });

  test('selecting partner plan shows partner selection', async () => {
    render(<PlanForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_form.group/ }));
    fireEvent.click(screen.getByRole('switch', { name: /app.admin.plan_form.partner_plan/ }));
    expect(screen.getByLabelText(/app.admin.plan_form.notified_partner/));
    expect(screen.findByRole('button', { name: /app.admin.plan_form.new_user/ }));
  });

  test('creating a new partner selects him by default', async () => {
    render(<PlanForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_form.group/ }));
    fireEvent.click(screen.getByRole('switch', { name: /app.admin.plan_form.partner_plan/ }));
    fireEvent.click(screen.getByRole('button', { name: /app.admin.plan_form.new_user/ }));
    await waitFor(() => screen.getByText('app.admin.partner_modal.title'));
    fireEvent.change(screen.getByLabelText(/app.admin.partner_modal.first_name/), { target: { value: 'Wolfgang Amadeus' } });
    fireEvent.change(screen.getByLabelText(/app.admin.partner_modal.surname/), { target: { value: 'Mozart' } });
    fireEvent.change(screen.getByLabelText(/app.admin.partner_modal.email/), { target: { value: 'mozart@example.com' } });
    // The following query contains { hidden: true }.
    // This is a workaround because react-modal adds aria-hidden to <body> which breaks accessibility
    fireEvent.click(screen.getByRole('button', { name: /app.admin.partner_modal.create_partner/, hidden: true }));
    await waitFor(() => screen.getByText(/app.admin.plan_form.alert_partner_notification/));
    expect(screen.getByText(/app.admin.plan_form.alert_partner_notification/)).toBeInTheDocument();
  });
});
