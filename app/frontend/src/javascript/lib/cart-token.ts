import Cookies from 'js-cookie';

export const cartCookieName = 'fablab_cart_token';
export const cartCookieExpire = 7;

export const getCartToken = () =>
  Cookies.get(cartCookieName);

export const setCartToken = (cartToken: string) => {
  const cookieOptions = {
    expires: cartCookieExpire
  };

  Cookies.set(
    cartCookieName,
    cartToken,
    cookieOptions
  );
};

export const removeCartToken = () => {
  Cookies.remove(cartCookieName);
};
