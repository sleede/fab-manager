import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { PlanForm } from 'components/plans/plan-form';
import { Plan } from 'models/plan';
import selectEvent from 'react-select-event';
import userEvent from '@testing-library/user-event';
import plans from '../../__fixtures__/plans';
import { tiptapEvent } from '../../__lib__/tiptap';

describe('PlanForm', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();
  const beforeSubmit = jest.fn();

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

  test('create new plan', async () => {
    render(<PlanForm action="create" onError={onError} onSuccess={onSuccess} beforeSubmit={beforeSubmit} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.plan_form.group/ }));
    const user = userEvent.setup();
    // base_name
    fireEvent.change(screen.getByLabelText(/app.admin.plan_form.name/), { target: { value: 'Test Plan' } });
    // group_id = 1
    await selectEvent.select(screen.getByLabelText(/app.admin.plan_form.group/), 'Standard');
    // plan_category_id = 1
    await selectEvent.select(screen.getByLabelText(/app.admin.plan_form.category/), 'beginners');
    // amount
    fireEvent.change(screen.getByLabelText(/app.admin.plan_form.subscription_price/), { target: { value: 25.21 } });
    // ui_weight
    fireEvent.change(screen.getByLabelText(/app.admin.plan_form.visual_prominence/), { target: { value: 10 } });
    // is_rolling
    await user.click(screen.getByLabelText(/app.admin.plan_form.rolling_subscription/));
    // monthly_payment
    await user.click(screen.getByLabelText(/app.admin.plan_form.monthly_payment/));
    // description
    await tiptapEvent.type(screen.getByLabelText(/app.admin.plan_form.description/), 'Lorem ipsum dolor sit amet');
    // plan_file_attributes.attachment_files
    const file = new File(['(⌐□_□)'], 'document.pdf', { type: 'application/pdf' });
    await user.upload(screen.getByLabelText(/app.admin.plan_form.information_sheet/), file);
    // interval_count
    fireEvent.change(screen.getByLabelText(/app.admin.plan_form.number_of_periods/), { target: { value: 6 } });
    // interval
    await selectEvent.select(screen.getByLabelText(/app.admin.plan_form.period/), 'app.admin.plan_form.month');
    // advanced_accounting_attributes.code
    fireEvent.change(screen.getByLabelText(/app.admin.advanced_accounting_form.code/), { target: { value: '705200' } });
    // advanced_accounting_attributes.analytical_section
    fireEvent.change(screen.getByLabelText(/app.admin.advanced_accounting_form.analytical_section/), { target: { value: '9B20A' } });
    // send the form
    fireEvent.click(screen.getByRole('button', { name: /app.admin.plan_form.ACTION_plan/ }));
    await waitFor(() => {
      const expected: Plan = {
        base_name: 'Test Plan',
        type: 'Plan',
        group_id: 1,
        plan_category_id: 1,
        amount: 25.21,
        ui_weight: 10,
        is_rolling: true,
        monthly_payment: true,
        description: '<p>Lorem ipsum dolor sit amet</p>',
        interval: 'month',
        interval_count: 6,
        all_groups: false,
        partnership: false,
        disabled: false,
        advanced_accounting_attributes: {
          analytical_section: '9B20A',
          code: '705200'
        },
        plan_file_attributes: {
          _destroy: false,
          attachment_files: expect.any(FileList)
        }
      };
      expect(beforeSubmit).toHaveBeenCalledWith(expect.objectContaining(expected));
    });
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
