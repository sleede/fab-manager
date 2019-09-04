/* global Stripe */

Application.Directives.directive('stripeForm', ['$window',
  function ($window) {
    return ({
      restrict: 'A',
      link: ($scope, element, attributes) => {
        const stripe = Stripe('<%= Rails.application.secrets.stripe_publishable_key %>');
        const elements = stripe.elements();

        const style = {
          base: {
            color: '#32325d',
            fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
            fontSmoothing: 'antialiased',
            fontSize: '16px',
            '::placeholder': {
              color: '#aab7c4'
            }
          },
          invalid: {
            color: '#fa755a',
            iconColor: '#fa755a'
          }
        };

        const card = elements.create('card', { style, hidePostalCode: true });

        card.addEventListener('change', function ({ error }) {
          const displayError = document.getElementById('card-errors');
          if (error) {
            displayError.textContent = error.message;
          } else {
            displayError.textContent = '';
          }
        });

        // Add an instance of the card Element into the `card-element` <div>.
        const form = angular.element(element);
        const cardElement = form.find('#card-element');
        card.mount(cardElement[0]);

        form.bind('submit', async () => {
          const button = form.find('button');
          button.prop('disabled', true);

          // TODO https://stripe.com/docs/payments/payment-intents/web-manual
          const { paymentMethod, error } = await stripe.createPaymentMethod('card', cardElement);
          if (error) {
            // Show error in payment form
          } else {
            // Send paymentMethod.id to your server (see Step 2)
            const response = await fetch('/ajax/confirm_payment', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ payment_method_id: paymentMethod.id })
            });

            const json = await response.json();

            // Handle server response (see Step 3)
            $scope.$apply(function () {
              $scope[form].apply($scope, json);
            });
          }
        });
      }
    });
  }]);
