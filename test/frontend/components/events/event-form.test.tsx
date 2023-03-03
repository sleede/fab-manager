import { EventForm } from 'components/events/event-form';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import selectEvent from 'react-select-event';
import eventPriceCategories from '../../__fixtures__/event_price_categories';

describe('EventForm', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('render create EventForm', async () => {
    render(<EventForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.event_form.event_category/ }));
    expect(screen.getByLabelText(/app.admin.event_form.title/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.matching_visual/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.description/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.event_category/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.event_themes/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.age_range/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.start_date/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.end_date/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.all_day/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.start_time/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.end_time/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.recurrence/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form._and_ends_on/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.seats_available/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.standard_rate/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.event_form.add_price/ })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.event_form.add_a_new_file/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.code/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.analytical_section/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.event_form.save/ })).toBeInTheDocument();
  });

  test('all day event hides the time inputs', async () => {
    render(<EventForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.event_form.event_category/ }));
    const user = userEvent.setup();
    await user.click(screen.getByLabelText(/app.admin.event_form.all_day/));
    expect(screen.queryByLabelText(/app.admin.event_form.start_time/)).toBeNull();
    expect(screen.queryByLabelText(/app.admin.event_form.end_time/)).toBeNull();
  });

  test('recurrent event requires end date', async () => {
    render(<EventForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.event_form.event_category/ }));
    await selectEvent.select(screen.getByLabelText(/app.admin.event_form.recurrence/), 'app.admin.event_form.recurring.every_week');
    expect(screen.getByLabelText(/app.admin.event_form._and_ends_on/).closest('label')).toHaveClass('is-required');
  });

  test('adding a second custom rate', async () => {
    render(<EventForm action="create" onError={onError} onSuccess={onSuccess} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.event_form.event_category/ }));
    // add a first category
    fireEvent.click(screen.getByRole('button', { name: /app.admin.event_form.add_price/ }));
    expect(screen.getByLabelText(/app.admin.event_form.fare_class/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.event_form.price/)).toBeInTheDocument();
    await selectEvent.select(screen.getByLabelText(/app.admin.event_form.fare_class/), eventPriceCategories[0].name);
    fireEvent.change(screen.getByLabelText(/app.admin.event_form.price/), { target: { value: 10 } });
    // add a second category
    fireEvent.click(screen.getByRole('button', { name: /app.admin.event_form.add_price/ }));
    expect(screen.getAllByLabelText(/app.admin.event_form.fare_class/)[0]).toBeDisabled();
    await selectEvent.openMenu(screen.getAllByLabelText(/app.admin.event_form.fare_class/)[1]);
    expect(screen.getAllByText(eventPriceCategories[0].name).find(element => element.classList.contains('rs__option'))).toHaveAttribute('aria-disabled', 'true');
  });
});
