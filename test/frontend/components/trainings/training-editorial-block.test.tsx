import { render, screen, waitFor } from '@testing-library/react';
import { TrainingEditorialBlock } from '../../../../app/frontend/src/javascript/components/trainings/training-editorial-block';

// Trainings Editorial Block
describe('Trainings Editorial Block', () => {
  test('should render a banner', async () => {
    const onError = jest.fn();

    render(<TrainingEditorialBlock onError={onError} />);

    await waitFor(() => screen.getByText('Test for Banner Content in Trainings'));
    await waitFor(() => screen.getByText('Test for Banner Button in Trainings'));
  });
});
