import { UserProfileForm } from '../../../../app/frontend/src/javascript/components/user/user-profile-form';
import { render, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { members, admins } from '../../__fixtures__/users';
import { loginAs } from '../../__lib__/auth';

describe('UserProfileForm', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('render UserProfileForm', async () => {
    loginAs(admins[0]);
    render(<UserProfileForm onError={onError}
                            action="create"
                            user={members[0]}
                            operator={admins[0]}
                            onSuccess={onSuccess} />);
    await waitFor(() => screen.getByLabelText(/app.shared.user_profile_form.external_id/));
    expect(screen.getByRole('button', { name: /app.shared.avatar_input.add_an_avatar/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.gender_input.man/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.gender_input.woman/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.surname/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.first_name/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.date_of_birth/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.phone_number/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.address/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.pseudonym/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.external_id/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.email_address/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.password_input.new_password/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.password_input.confirm_password/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.declare_organization/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.website/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.job/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.interests/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.CAD_softwares_mastered/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.allow_public_profile/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.allow_newsletter/)).toBeInTheDocument();
  });

  test('admin should see the private note', async () => {
    loginAs(admins[0]);
    render(<UserProfileForm onError={onError}
                            action="create"
                            user={members[0]}
                            operator={admins[0]}
                            onSuccess={onSuccess} />);
    await waitFor(() => screen.getByLabelText(/app.shared.user_profile_form.external_id/));
    expect(screen.getByRole('button', { name: /app.shared.avatar_input.add_an_avatar/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.shared.user_profile_form.note/)).toBeInTheDocument();
  });

  test('member should not see the private note', async () => {
    loginAs(members[0]);
    render(<UserProfileForm onError={onError}
                            action="update"
                            user={members[0]}
                            operator={members[0]}
                            onSuccess={onSuccess} />);
    await waitFor(() => screen.getByLabelText(/app.shared.user_profile_form.external_id/));
    expect(screen.getByRole('button', { name: /app.shared.avatar_input.add_an_avatar/ })).toBeInTheDocument();
    expect(screen.queryByLabelText(/app.shared.user_profile_form.note/)).toBeNull();
  });
});
