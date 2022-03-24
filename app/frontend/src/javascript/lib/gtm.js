// this script loads the google tag manager, used by Google Analytics V4
(function () {
  const GTM = {};

  window.dataLayer = window.dataLayer || [];
  function gtag () { window.dataLayer.push(arguments); }

  GTM.enableAnalytics = function (trackingId) {
    gtag('js', new Date());
    gtag('config', trackingId);

    const node = document.createElement('script');
    const firstScript = document.getElementsByTagName('script')[0];
    node.async = true;
    node.src = `//www.googletagmanager.com/gtag/js?id=${trackingId}`;
    firstScript.parentNode.insertBefore(node, firstScript);
  };

  GTM.trackPage = function (url, title) {
    gtag('event', 'page_view', {
      page_location: url,
      page_title: title
    });
  };

  GTM.trackLogin = function () {
    gtag('event', 'login');
  };

  GTM.trackPurchase = function (transactionId, value) {
    gtag('event', 'purchase', {
      transaction_id: transactionId,
      value: value,
      currency: Fablab.intl_currency
    });
  };

  this.GTM = GTM;

  if (typeof module !== 'undefined' && module !== null) {
    module.exports = GTM;
  }
}).call(this);
