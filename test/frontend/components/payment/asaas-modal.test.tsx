import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { AsaasModal } from '../../../../app/frontend/src/javascript/components/payment/asaas/asaas-modal';
import WalletAPI from '../../../../app/frontend/src/javascript/api/wallet';
import PriceAPI from '../../../../app/frontend/src/javascript/api/price';
import AsaasAPI from '../../../../app/frontend/src/javascript/api/asaas';

jest.mock('../../../../app/frontend/src/javascript/components/payment/wallet-info', () => ({
  WalletInfo: () => <div data-testid="wallet-info" />
}));

jest.mock('../../../../app/frontend/src/javascript/components/base/loader', () => ({
  Loader: ({ children }) => <>{children}</>
}));

jest.mock('../../../../app/frontend/src/javascript/components/base/fab-modal', () => ({
  FabModal: ({ title, children }) => <div><h1>{title}</h1>{children}</div>,
  ModalSize: { medium: 'medium' }
}));

jest.mock('../../../../app/frontend/src/javascript/api/wallet', () => ({
  __esModule: true,
  default: { getByUser: jest.fn() }
}));

jest.mock('../../../../app/frontend/src/javascript/api/price', () => ({
  __esModule: true,
  default: { compute: jest.fn() }
}));

jest.mock('../../../../app/frontend/src/javascript/api/asaas', () => ({
  __esModule: true,
  default: {
    createCartPayment: jest.fn(),
    createOrderPayment: jest.fn(),
    paymentStatus: jest.fn()
  }
}));

describe('AsaasModal', () => {
  const toggleModal = jest.fn();
  const afterSuccess = jest.fn();
  const onError = jest.fn();
  const currentUser = { id: 1 };
  const customer = { id: 1 };
  const cart = {
    customer_id: 1,
    payment_method: 'transfer',
    payment_schedule: false,
    items: [{ reservation: { reservable_id: 1, reservable_type: 'Machine', slots_reservations_attributes: [{ slot_id: 1 }] } }]
  };
  const mockedWalletAPI = WalletAPI as jest.Mocked<typeof WalletAPI>;
  const mockedPriceAPI = PriceAPI as jest.Mocked<typeof PriceAPI>;
  const mockedAsaasAPI = AsaasAPI as jest.Mocked<typeof AsaasAPI>;
  let setIntervalSpy: jest.SpyInstance;

  beforeEach(() => {
    jest.clearAllMocks();
    setIntervalSpy = jest.spyOn(window, 'setInterval').mockImplementation(() => 1 as unknown as number);
    mockedWalletAPI.getByUser.mockResolvedValue({ amount: 0 } as never);
  });

  afterEach(() => {
    setIntervalSpy.mockRestore();
  });

  test('disables pix generation below minimum amount', async () => {
    mockedPriceAPI.compute.mockResolvedValue({ price: 4, price_without_coupon: 4 } as never);

    render(<AsaasModal isOpen={true}
      toggleModal={toggleModal}
      afterSuccess={afterSuccess}
      onError={onError}
      cart={cart}
      currentUser={currentUser}
      customer={customer} />);

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /app.shared.asaas_modal.generate_pix_of_AMOUNT/ })).toBeDisabled();
    });

    fireEvent.change(screen.getByLabelText(/app.shared.asaas_modal.cpf/), { target: { value: '06667105978' } });

    expect(screen.getByText(/app.shared.asaas_modal.minimum_amount_error/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.shared.asaas_modal.generate_pix_of_AMOUNT/ })).toBeDisabled();
  });

  test('creates payment with normalized cpf and shows qr payload', async () => {
    mockedPriceAPI.compute.mockResolvedValue({ price: 10, price_without_coupon: 10 } as never);
    mockedAsaasAPI.createCartPayment.mockResolvedValue({
      token: 'tok_123',
      status: 'waiting_payment',
      pix_payload: 'pix-code',
      pix_encoded_image: 'image-data',
      pix_expiration_at: '2026-03-28T12:00:00Z'
    } as never);
    mockedAsaasAPI.paymentStatus.mockResolvedValue({ token: 'tok_123', status: 'waiting_payment', pix_payload: 'pix-code', pix_encoded_image: 'image-data', pix_expiration_at: '2026-03-28T12:00:00Z' } as never);

    render(<AsaasModal isOpen={true}
      toggleModal={toggleModal}
      afterSuccess={afterSuccess}
      onError={onError}
      cart={cart}
      currentUser={currentUser}
      customer={customer} />);

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /app.shared.asaas_modal.generate_pix_of_AMOUNT/ })).toBeDisabled();
    });

    fireEvent.change(screen.getByLabelText(/app.shared.asaas_modal.cpf/), { target: { value: '066.671.059-78' } });

    const button = screen.getByRole('button', { name: /app.shared.asaas_modal.generate_pix_of_AMOUNT/ });
    await waitFor(() => expect(button).not.toBeDisabled());

    fireEvent.click(button);

    await waitFor(() => {
      expect(mockedAsaasAPI.createCartPayment).toHaveBeenCalledWith(cart, '06667105978');
    });

    expect(screen.getByDisplayValue('pix-code')).toBeInTheDocument();
  });
});
