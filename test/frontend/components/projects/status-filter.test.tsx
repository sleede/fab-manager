import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { StatusFilter } from '../../../../app/frontend/src/javascript/components/projects/status/status-filter';

// Status filter is a part of Project Gallery
describe('Status Filter', () => {
  test('should call onChange with option when selecting and shifting option', async () => {
    const onError = jest.fn();
    const onFilterChange = jest.fn();

    render(<StatusFilter onError={onError} onFilterChange={onFilterChange}/>);

    // Wait for component to render with list of statuses
    await waitFor(() => screen.getByLabelText(/app.public.status_filter.select_status/));

    fireEvent.keyDown(screen.getByLabelText(/app.public.status_filter.select_status/), { key: 'ArrowDown' });
    await waitFor(() => screen.getByText('Mocked Status 1'));
    fireEvent.click(screen.getByText('Mocked Status 1'));

    expect(onFilterChange).toHaveBeenCalledWith({ name: 'Mocked Status 1', id: 1 });

    fireEvent.keyDown(screen.getByLabelText(/app.public.status_filter.select_status/), { key: 'ArrowDown' });
    await waitFor(() => screen.getByText('Mocked Status 2'));
    fireEvent.click(screen.getByText('Mocked Status 2'));

    expect(onFilterChange).toHaveBeenCalledTimes(2);
    expect(onFilterChange).toHaveBeenCalledWith({ name: 'Mocked Status 2', id: 2 });
  });
});
