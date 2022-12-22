import { PasswordStrength } from '../../../../app/frontend/src/javascript/components/user/password-strength';
import { render, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

describe('PasswordStrength', () => {
  test('no password', async () => {
    render(<PasswordStrength />);
    expect(document.querySelector('.password-strength')).toBeEmptyDOMElement();
  });

  test('password does not meet requirements', async () => {
    render(<PasswordStrength password="weak"/>);
    expect(screen.getByText('app.shared.password_strength.not_in_requirements')).toBeInTheDocument();
  });

  test('simple password meet requirements', async () => {
    render(<PasswordStrength password="Passw0rd----"/>);
    await waitFor(() =>
      expect(screen.getByText('app.shared.password_strength.1')).toBeInTheDocument()
    );
    expect(screen.queryByText('app.shared.password_strength.not_in_requirements')).toBeNull();
  });

  test('complexe password meet requirements', async () => {
    render(<PasswordStrength password="5y&Ka@7HQ6FnQnnmx%p6!z6e1f"/>);
    await waitFor(() =>
      expect(screen.getByText('app.shared.password_strength.4')).toBeInTheDocument()
    );
    expect(screen.queryByText('app.shared.password_strength.not_in_requirements')).toBeNull();
  });
});
