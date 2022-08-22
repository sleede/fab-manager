import { useState, useEffect } from 'react';
import { Order } from '../models/order';
import CartAPI from '../api/cart';
import { getCartToken, setCartToken } from '../lib/cart-token';

export default function useCart () {
  const [cart, setCart] = useState<Order>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function createCart () {
      const currentCartToken = getCartToken();
      const data = await CartAPI.create(currentCartToken);
      setCart(data);
      setLoading(false);
      setCartToken(data.token);
    }
    setLoading(true);
    try {
      createCart();
    } catch (e) {
      setLoading(false);
      setError(e);
    }
  }, []);

  const reloadCart = async () => {
    setLoading(true);
    const currentCartToken = getCartToken();
    const data = await CartAPI.create(currentCartToken);
    setCart(data);
    setLoading(false);
  };

  return { loading, cart, error, setCart, reloadCart };
}
