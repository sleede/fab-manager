import { render, fireEvent, screen, waitFor, waitForElementToBeRemoved } from '@testing-library/react';
import { StatusSettings } from '../../../../app/frontend/src/javascript/components/projects/status/status-settings';

// Status Settings are a part of Project Settings in Admin Section
describe('Status Settings', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('display all Statuses', async () => {
    render(<StatusSettings onError={onError} onSuccess={onSuccess}/>);
    await waitFor(() => screen.getByTestId('status-settings'));
    expect(screen.getByText('Mocked Status 1')).toBeDefined();
    expect(screen.getByText('Mocked Status 2')).toBeDefined();
  });

  test('can create a Status', async () => {
    render(<StatusSettings onError={onError} onSuccess={onSuccess}/>);
    await waitFor(() => screen.getByTestId('status-settings'));
    fireEvent.click(screen.getByRole('button', { name: /app.admin.projects_setting.add/ }));
    fireEvent.change(screen.getByLabelText(/app.admin.projects_setting_option_form.name/), { target: { value: 'My new Status' } });
    fireEvent.click(screen.getByRole('button', { name: /app.admin.projects_setting_option_form.save/ }));
    await waitFor(() => screen.getByText('My new Status'));
    expect(screen.getByText('My new Status')).toBeDefined();
  });

  test('can update a Status', async () => {
    render(<StatusSettings onError={onError} onSuccess={onSuccess}/>);
    await waitFor(() => screen.getByTestId('status-settings'));
    fireEvent.click(screen.getByRole('button', { name: /app.admin.projects_setting_option.edit Mocked Status 2/ }));
    fireEvent.change(screen.getByLabelText(/app.admin.projects_setting_option_form.name/), { target: { value: 'My updated Status' } });
    fireEvent.click(screen.getByRole('button', { name: /app.admin.projects_setting_option_form.save/ }));
    await waitFor(() => expect(screen.getByText('My updated Status')));
  });

  test('can delete a Status', async () => {
    render(<StatusSettings onError={onError} onSuccess={onSuccess}/>);
    await waitFor(() => screen.getByTestId('status-settings'));
    fireEvent.click(screen.getByRole('button', { name: /app.admin.projects_setting_option.delete_option Mocked Status 1/ }));
    await waitForElementToBeRemoved(screen.getByText('Mocked Status 1'));
    expect(screen.queryByText('Mocked Status 1')).toBeNull();
    expect(screen.queryByText('Mocked Status 2')).toBeDefined();
  });
});
