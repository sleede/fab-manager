import { render, screen, waitFor } from '@testing-library/react';
import { NotificationsList } from '../../../../app/frontend/src/javascript/components/notifications/notifications-list';

// Notifications list in Notification Center
describe('Notifications list', () => {
  test('should render the correct list', async () => {
    const onError = jest.fn();

    render(<NotificationsList onError={onError} />);
    await waitFor(() => screen.getByTestId('notifications-list'));
    expect(screen.getByText('Decription of the first notification')).toBeDefined();
    expect(screen.getByText('Decription of the second notification')).toBeDefined();
    expect(screen.getByText('Decription of the third notification')).toBeDefined();
  });
});
