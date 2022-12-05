import { ProductForm } from '../../../../app/frontend/src/javascript/components/store/product-form';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import products from '../../__fixtures__/products';
import machines from '../../__fixtures__/machines';
import { uiRouter } from '../../__lib__/ui-router';

describe('ProductForm', () => {
  const onError = jest.fn();
  const onSuccess = jest.fn();

  test('render ProductForm', async () => {
    render(<ProductForm product={products[0]}
                        title={'Update a product'}
                        onSuccess={onSuccess}
                        onError={onError}
                        uiRouter={uiRouter} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.store.product_form.linking_product_to_category/ }));
    expect(screen.getByLabelText(/app.admin.store.product_form.name/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.sku/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.slug/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_active_price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.quantity_min/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.store.product_form.add_product_image/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.linking_product_to_category/)).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /app.admin.store.product_form.assigning_machines/ })).toBeInTheDocument();
    for (const machine of machines) {
      expect(screen.getByLabelText(machine.name)).toBeInTheDocument();
    }
    expect(screen.getByLabelText(/app.admin.store.product_form.product_description/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /app.admin.store.product_form.add_product_file/ })).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.code/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.advanced_accounting_form.analytical_section/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole('tab', { name: /app.admin.store.product_form.stock_management/ }));
    await waitFor(() =>
      expect(screen.getByRole('heading', { name: /app.admin.store.product_stock_form.stock_up_to_date/ })).toBeInTheDocument()
    );
    expect(screen.getByLabelText(/app.admin.store.product_stock_form.stock_threshold_toggle/)).toBeInTheDocument();
  });

  test('toggle off the price', async () => {
    render(<ProductForm product={products[0]}
                        title={'Update a product'}
                        onSuccess={onSuccess}
                        onError={onError}
                        uiRouter={uiRouter} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.store.product_form.linking_product_to_category/ }));
    expect(screen.getByLabelText(/app.admin.store.product_form.price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.quantity_min/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).toBeChecked();
    fireEvent.click(screen.getByLabelText(/app.admin.store.product_form.is_active_price/));
    expect(screen.queryByLabelText(/app.admin.store.product_form.price/)).toBeNull();
    expect(screen.queryByLabelText(/app.admin.store.product_form.quantity_min/)).toBeNull();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).not.toBeChecked();
  });

  test('toggle off the visibility', async () => {
    render(<ProductForm product={products[0]}
                        title={'Update a product'}
                        onSuccess={onSuccess}
                        onError={onError}
                        uiRouter={uiRouter} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.store.product_form.linking_product_to_category/ }));
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_active_price/)).toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.quantity_min/)).toBeInTheDocument();
    fireEvent.click(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/));
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).not.toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_active_price/)).toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.quantity_min/)).toBeInTheDocument();
  });

  test('toggle on the visibility', async () => {
    render(<ProductForm product={products[1]}
                        title={'Update a product'}
                        onSuccess={onSuccess}
                        onError={onError}
                        uiRouter={uiRouter} />);
    await waitFor(() => screen.getByRole('combobox', { name: /app.admin.store.product_form.linking_product_to_category/ }));
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).not.toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_active_price/)).not.toBeChecked();
    expect(screen.queryByLabelText(/app.admin.store.product_form.price/)).toBeNull();
    expect(screen.queryByLabelText(/app.admin.store.product_form.quantity_min/)).toBeNull();
    fireEvent.click(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/));
    expect(screen.getByLabelText(/app.admin.store.product_form.is_show_in_store/)).toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.is_active_price/)).toBeChecked();
    expect(screen.getByLabelText(/app.admin.store.product_form.price/)).toBeInTheDocument();
    expect(screen.getByLabelText(/app.admin.store.product_form.quantity_min/)).toBeInTheDocument();
  });
});
