import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { StatusFilter } from '../../../../app/frontend/src/javascript/components/projects/status-filter';

describe('Status Filter', () => {
  test('should call onChange with option when selecting and shifting option', async () => {
    const onError = jest.fn();
    const onFilterChange = jest.fn();

    render(<StatusFilter onError={onError} onFilterChange={onFilterChange}/>);

    expect(onFilterChange).toHaveBeenCalledTimes(0);

    fireEvent.keyDown(screen.getByLabelText(/app.public.status_filter.all_statuses/), { key: 'ArrowDown' });
    await waitFor(() => screen.getByText('Mocked Status 1'));
    fireEvent.click(screen.getByText('Mocked Status 1'));

    expect(onFilterChange).toHaveBeenCalledWith({ label: 'Mocked Status 1', value: 1 });

    fireEvent.keyDown(screen.getByLabelText(/app.public.status_filter.all_statuses/), { key: 'ArrowDown' });
    await waitFor(() => screen.getByText('Mocked Status 2'));
    fireEvent.click(screen.getByText('Mocked Status 2'));

    expect(onFilterChange).toHaveBeenCalledTimes(2);
    expect(onFilterChange).toHaveBeenCalledWith({ label: 'Mocked Status 2', value: 2 });
  });
});
