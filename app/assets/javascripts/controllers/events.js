/* eslint-disable
    camelcase,
    handle-callback-err,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict'

Application.Controllers.controller('EventsController', ['$scope', '$state', 'Event', 'categoriesPromise', 'themesPromise', 'ageRangesPromise',
  function ($scope, $state, Event, categoriesPromise, themesPromise, ageRangesPromise) {
  /* PUBLIC SCOPE */

    // # The events displayed on the page
    $scope.events = []

    // # The currently displayed page number
    $scope.page = 1

    // # List of categories for the events
    $scope.categories = categoriesPromise

    // # List of events themes
    $scope.themes = themesPromise

    // # List of age ranges
    $scope.ageRanges = ageRangesPromise

    // # Hide or show the 'load more' button
    $scope.noMoreResults = false

    // # Active filters for the events list
    $scope.filters = {
      category_id: null,
      theme_id: null,
      age_range_id: null
    }

    // $scope.monthNames = [<%= t('date.month_names')[1..-1].map { |m| "\"#{m}\"" }.join(', ') %>]

    // #
    // Adds a resultset of events to the bottom of the page, grouped by month
    // #
    $scope.loadMoreEvents = function () {
      $scope.page += 1
      return Event.query(Object.assign({ page: $scope.page }, $scope.filters), function (data) {
        $scope.events = $scope.events.concat(data)
        groupEvents($scope.events)

        if (!data[0] || (data[0].nb_total_events <= $scope.events.length)) {
          return $scope.noMoreResults = true
        }
      })
    }

    // #
    // Callback to redirect the user to the specified event page
    // @param event {{id:number}}
    // #
    $scope.showEvent = event => $state.go('app.public.events_show', { id: event.id })

    // #
    // Callback to refresh the events list according to the filters set
    // #
    $scope.filterEvents = function () {
    // reinitialize results datasets
      $scope.page = 1
      $scope.eventsGroupByMonth = {}
      $scope.events = []
      $scope.monthOrder = []
      $scope.noMoreResults = false

      // run a search query
      return Event.query(Object.assign({ page: $scope.page }, $scope.filters), function (data) {
        $scope.events = data
        groupEvents(data)

        if (!data[0] || (data[0].nb_total_events <= $scope.events.length)) {
          return $scope.noMoreResults = true
        }
      })
    }

    // #
    // Test if the provided event occurs on a single day or on many days
    // @param event {{start_date:Date, end_date:Date}} Event object as retreived from the API
    // @return {boolean} false if the event occurs on many days
    // #
    $scope.onSingleDay = event => moment(event.start_date).isSame(event.end_date, 'day')

    /* PRIVATE SCOPE */

    // #
    // Kind of constructor: these actions will be realized first when the controller is loaded
    // #
    const initialize = () => $scope.filterEvents()

    // #
    // Group the provided events by month/year and concat them with existing results
    // Then compute the ordered list of months for the complete resultset.
    // Affect the resulting events groups in $scope.eventsGroupByMonth and the ordered month keys in $scope.monthOrder.
    // @param {Array} Events retrived from the API
    // #
    var groupEvents = function (events) {
      if (events.length > 0) {
        const eventsGroupedByMonth = _.groupBy(events, obj => _.map(['month_id', 'year'], (key, value) => obj[key]))
        $scope.eventsGroupByMonth = Object.assign($scope.eventsGroupByMonth, eventsGroupedByMonth)
        return $scope.monthOrder = Object.keys($scope.eventsGroupByMonth)
      }
    }

    // # !!! MUST BE CALLED AT THE END of the controller
    return initialize()
  }
])

Application.Controllers.controller('ShowEventController', ['$scope', '$state', '$stateParams', 'Event', '$uibModal', 'Member', 'Reservation', 'Price', 'CustomAsset', 'eventPromise', 'growl', '_t', 'Wallet', 'helpers', 'dialogs', 'priceCategoriesPromise', 'settingsPromise',
  function ($scope, $state, $stateParams, Event, $uibModal, Member, Reservation, Price, CustomAsset, eventPromise, growl, _t, Wallet, helpers, dialogs, priceCategoriesPromise, settingsPromise) {
  /* PUBLIC SCOPE */

    // # reservations for the currently shown event
    $scope.reservations = []

    // # user to deal with
    $scope.ctrl =
      { member: {} }

    // # parameters for a new reservation
    $scope.reserve = {
      nbPlaces: {
        normal: []
      },
      nbReservePlaces: 0,
      tickets: {},
      toReserve: false,
      amountTotal: 0,
      totalNoCoupon: 0,
      totalSeats: 0
    }

    // # Discount coupon to apply to the basket, if any
    $scope.coupon =
    { applied: null }

    // # Get the details for the current event (event's id is recovered from the current URL)
    $scope.event = eventPromise

    // # List of price categories for the events
    $scope.priceCategories = priceCategoriesPromise

    // # Global config: is the user authorized to change his bookings slots?
    $scope.enableBookingMove = (settingsPromise.booking_move_enable === 'true')

    // # Global config: delay in hours before a booking while changing the booking slot is forbidden
    $scope.moveBookingDelay = parseInt(settingsPromise.booking_move_delay)

    // # Message displayed to the end user about rules that applies to events reservations
    $scope.eventExplicationsAlert = settingsPromise.event_explications_alert

    // #
    // Callback to delete the provided event (admins only)
    // @param event {$resource} angular's Event $resource
    // #
    $scope.deleteEvent = event =>
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('confirmation_required'),
              msg: _t('do_you_really_want_to_delete_this_event')
            }
          }
        }
      }
      , () =>
      // the admin has confirmed, delete
        event.$delete(function () {
          $state.go('app.public.events_list')
          return growl.info(_t('event_successfully_deleted'))
        }
        , error => growl.error(_t('unable_to_delete_the_event_because_some_users_alredy_booked_it')))
      )

    // #
    // Callback to call when the number of tickets to book changes in the current booking
    // #
    $scope.changeNbPlaces = function () {
    // compute the total remaing places
      let remain = $scope.event.nb_free_places - $scope.reserve.nbReservePlaces
      for (let ticket in $scope.reserve.tickets) {
        remain -= $scope.reserve.tickets[ticket]
      }
      // we store the total number of seats booked, this is used to know if the 'pay' button must be shown
      $scope.reserve.totalSeats = $scope.event.nb_free_places - remain

      // update the availables seats for full price tickets
      const fullPriceRemains = $scope.reserve.nbReservePlaces + remain
      $scope.reserve.nbPlaces.normal = __range__(0, fullPriceRemains, true)

      // update the available seats for other prices tickets
      for (let key in $scope.reserve.nbPlaces) {
        if (key !== 'normal') {
          const priceRemain = $scope.reserve.tickets[key] + remain
          $scope.reserve.nbPlaces[key] = __range__(0, priceRemain, true)
        }
      }

      // recompute the total price
      return $scope.computeEventAmount()
    }

    // #
    // Callback to reset the current reservation parameters
    // @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
    // #
    $scope.cancelReserve = function (e) {
      e.preventDefault()
      return resetEventReserve()
    }

    // #
    // Callback to allow the user to set the details for his reservation
    // #
    $scope.reserveEvent = function () {
      if ($scope.event.nb_total_places > 0) {
        $scope.reserveSuccess = false
        if (!$scope.isAuthenticated()) {
          return $scope.login(null, function (user) {
            $scope.reserve.toReserve = !$scope.reserve.toReserve
            if (user.role !== 'admin') {
              return $scope.ctrl.member = user
            }
          })
        } else {
          return $scope.reserve.toReserve = !$scope.reserve.toReserve
        }
      }
    }

    // #
    // Callback to deal with the reservations of the user selected in the dropdown list instead of the current user's
    // reservations. (admins only)
    // #
    $scope.updateMember = function () {
      resetEventReserve()
      $scope.reserveSuccess = false
      if ($scope.ctrl.member) {
        return Member.get({ id: $scope.ctrl.member.id }, function (member) {
          $scope.ctrl.member = member
          return getReservations($scope.event.id, 'Event', $scope.ctrl.member.id)
        })
      }
    }

    // #
    // Callback to trigger the payment process of the current reservation
    // #
    $scope.payEvent = function () {
    // first, we check that a user was selected
      if (Object.keys($scope.ctrl.member).length > 0) {
        const reservation = mkReservation($scope.ctrl.member, $scope.reserve, $scope.event)

        return Wallet.getWalletByUser({ user_id: $scope.ctrl.member.id }, function (wallet) {
          const amountToPay = helpers.getAmountToPay($scope.reserve.amountTotal, wallet.amount)
          if (($scope.currentUser.role !== 'admin') && (amountToPay > 0)) {
            return payByStripe(reservation)
          } else {
            if (($scope.currentUser.role === 'admin') || (amountToPay === 0)) {
              return payOnSite(reservation)
            }
          }
        })
      } else {
      // otherwise we alert, this error musn't occur when the current user is not admin
        return growl.error(_t('please_select_a_member_first'))
      }
    }

    // #
    // Callback to validate the booking of a free event
    // #
    $scope.validReserveEvent = function () {
      const reservation = {
        user_id: $scope.ctrl.member.id,
        reservable_id: $scope.event.id,
        reservable_type: 'Event',
        slots_attributes: [],
        nb_reserve_places: $scope.reserve.nbReservePlaces,
        tickets_attributes: []
      }
      // a single slot is used for events
      reservation.slots_attributes.push({
        start_at: $scope.event.start_date,
        end_at: $scope.event.end_date,
        availability_id: $scope.event.availability.id
      })
      // iterate over reservations per prices
      for (let price_id in $scope.reserve.tickets) {
        const seats = $scope.reserve.tickets[price_id]
        reservation.tickets_attributes.push({
          event_price_category_id: price_id,
          booked: seats
        })
      }
      // set the attempting marker
      $scope.attempting = true
      // save the reservation to the API
      return Reservation.save({ reservation }, function (reservation) {
      // reservation successfull
        afterPayment(reservation)
        return $scope.attempting = false
      }
      , function (response) {
      // reservation failed
        $scope.alerts = []
        $scope.alerts.push({
          msg: response.data.card[0],
          type: 'danger'
        })
        // unset the attempting marker
        return $scope.attempting = false
      })
    }

    // #
    // Callback to alter an already booked reservation date. A modal window will be opened to allow the user to choose
    // a new date for his reservation (if any available)
    // @param reservation {{id:number, reservable_id:number, nb_reserve_places:number}}
    // @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
    // #
    $scope.modifyReservation = function (reservation, e) {
      e.preventDefault()
      e.stopPropagation()

      const index = $scope.reservations.indexOf(reservation)
      return $uibModal.open({
        templateUrl: '<%= asset_path "events/modify_event_reservation_modal.html" %>',
        resolve: {
          event () { return $scope.event },
          reservation () { return reservation }
        },
        controller: ['$scope', '$uibModalInstance', 'event', 'reservation', 'Reservation', function ($scope, $uibModalInstance, event, reservation, Reservation) {
        // we copy the controller's resolved parameters into the scope
          $scope.event = event
          $scope.reservation = angular.copy(reservation)

          // set the reservable_id to the first available event
          for (e of Array.from(event.recurrence_events)) {
            if (e.nb_free_places > reservation.total_booked_seats) {
              $scope.reservation.reservable_id = e.id
              break
            }
          }

          // Callback to validate the new reservation's date
          $scope.ok = function () {
            let eventToPlace = null
            angular.forEach(event.recurrence_events, function (e) {
              if (e.id === parseInt($scope.reservation.reservable_id, 10)) {
                return eventToPlace = e
              }
            })
            $scope.reservation.slots[0].start_at = eventToPlace.start_date
            $scope.reservation.slots[0].end_at = eventToPlace.end_date
            $scope.reservation.slots[0].availability_id = eventToPlace.availability_id
            $scope.reservation.slots_attributes = $scope.reservation.slots
            $scope.attempting = true
            return Reservation.update({ id: reservation.id }, { reservation: $scope.reservation }, function (reservation) {
              $uibModalInstance.close(reservation)
              return $scope.attempting = true
            }
            , function (response) {
              $scope.alerts = []
              angular.forEach(response, (v, k) =>
                angular.forEach(v, err => $scope.alerts.push({ msg: k + ': ' + err, type: 'danger' }))
              )
              return $scope.attempting = false
            })
          }

          // Callback to cancel the modification
          return $scope.cancel = () => $uibModalInstance.dismiss('cancel')
        }
        ] })
        .result['finally'](null).then(function (reservation) {
          // remove the reservation from the user's reservations list for this event (occurrence)
          $scope.reservations.splice(index, 1)
          // add the number of places transfered (to the new date) to the total of free places for this event
          $scope.event.nb_free_places = $scope.event.nb_free_places + reservation.total_booked_seats
          // remove the number of places transfered from the total of free places of the receiving occurrance
          return angular.forEach($scope.event.recurrence_events, function (e) {
            if (e.id === parseInt(reservation.reservable.id, 10)) {
              return e.nb_free_places = e.nb_free_places - reservation.total_booked_seats
            }
          })
        })
    }

    // #
    // Checks if the provided reservation is able to be moved (date change)
    // @param reservation {{total_booked_seats:number}}
    // #
    $scope.reservationCanModify = function (reservation) {
      const slotStart = moment(reservation.slots[0].start_at)
      const now = moment()

      let isAble = false
      angular.forEach($scope.event.recurrence_events, function (e) {
        if (e.nb_free_places >= reservation.total_booked_seats) { return isAble = true }
      })
      return (isAble && $scope.enableBookingMove && (slotStart.diff(now, 'hours') >= $scope.moveBookingDelay))
    }

    // #
    // Compute the total amount for the current reservation according to the previously set parameters
    // and assign the result in $scope.reserve.amountTotal
    // #
    $scope.computeEventAmount = function () {
    // first we check that a user was selected
      if (Object.keys($scope.ctrl.member).length > 0) {
        const r = mkReservation($scope.ctrl.member, $scope.reserve, $scope.event)
        return Price.compute(mkRequestParams(r, $scope.coupon.applied), function (res) {
          $scope.reserve.amountTotal = res.price
          return $scope.reserve.totalNoCoupon = res.price_without_coupon
        })
      } else {
        return $scope.reserve.amountTotal = null
      }
    }

    // #
    // Return the URL allowing to share the current project on the Facebook social network
    // #
    $scope.shareOnFacebook = () => `https://www.facebook.com/share.php?u=${$state.href('app.public.events_show', { id: $scope.event.id }, { absolute: true }).replace('#', '%23')}`

    // #
    // Return the URL allowing to share the current project on the Twitter social network
    // #
    $scope.shareOnTwitter = () => `https://twitter.com/intent/tweet?url=${encodeURIComponent($state.href('app.public.events_show', { id: $scope.event.id }, { absolute: true }))}&text=${encodeURIComponent($scope.event.title)}`

    // #
    // Return the textual description of the conditions applyable to the given price's category
    // @param category_id {number} ID of the price's category
    // #
    $scope.getPriceCategoryConditions = function (category_id) {
      for (let cat of Array.from($scope.priceCategories)) {
        if (cat.id === category_id) {
          return cat.conditions
        }
      }
    }

    /* PRIVATE SCOPE */

    // #
    // Kind of constructor: these actions will be realized first when the controller is loaded
    // #
    const initialize = function () {
    // set the controlled user as the current user if the current user is not an admin
      if ($scope.currentUser) {
        if ($scope.currentUser.role !== 'admin') {
          $scope.ctrl.member = $scope.currentUser
        }
      }

      // initialize the "reserve" object with the event's data
      resetEventReserve()

      // if non-admin, get the current user's reservations into $scope.reservations
      if ($scope.currentUser) {
        getReservations($scope.event.id, 'Event', $scope.currentUser.id)
      }

      // watch when a coupon is applied to re-compute the total price
      return $scope.$watch('coupon.applied', function (newValue, oldValue) {
        if ((newValue !== null) || (oldValue !== null)) {
          return $scope.computeEventAmount()
        }
      })
    }

    // #
    // Retrieve the reservations for the couple event / user
    // @param reservable_id {number} the current event id
    // @param reservable_type {string} 'Event'
    // @param user_id {number} the user's id (current or managed)
    // #
    var getReservations = (reservable_id, reservable_type, user_id) =>
      Reservation.query({ reservable_id, reservable_type, user_id }).$promise.then(reservations => $scope.reservations = reservations)

    // #
    // Create an hash map implementing the Reservation specs
    // @param member {Object} User as retreived from the API: current user / selected user if current is admin
    // @param reserve {Object} Reservation parameters (places...)
    // @param event {Object} Current event
    // @return {{user_id:number, reservable_id:number, reservable_type:string, slots_attributes:Array<Object>, nb_reserve_places:number}}
    // #
    var mkReservation = function (member, reserve, event) {
      const reservation = {
        user_id: member.id,
        reservable_id: event.id,
        reservable_type: 'Event',
        slots_attributes: [],
        nb_reserve_places: reserve.nbReservePlaces,
        tickets_attributes: []
      }

      reservation.slots_attributes.push({
        start_at: event.start_date,
        end_at: event.end_date,
        availability_id: event.availability.id,
        offered: event.offered || false
      })

      for (let evt_px_cat of Array.from(event.prices)) {
        const booked = reserve.tickets[evt_px_cat.id]
        if (booked > 0) {
          reservation.tickets_attributes.push({
            event_price_category_id: evt_px_cat.id,
            booked
          })
        }
      }

      return reservation
    }

    // #
    // Format the parameters expected by /api/prices/compute or /api/reservations and return the resulting object
    // @param reservation {Object} as returned by mkReservation()
    // @param coupon {Object} Coupon as returned from the API
    // @return {{reservation:Object, coupon_code:string}}
    // #
    var mkRequestParams = function (reservation, coupon) {
      const params = {
        reservation,
        coupon_code: ((coupon ? coupon.code : undefined))
      }

      return params
    }

    // #
    // Set the current reservation to the default values. This implies to reservation form to be hidden.
    // #
    var resetEventReserve = function () {
      if ($scope.event) {
        $scope.reserve = {
          nbPlaces: {
            normal: __range__(0, $scope.event.nb_free_places, true)
          },
          nbReservePlaces: 0,
          tickets: {},
          toReserve: false,
          amountTotal: 0,
          totalSeats: 0
        }

        for (let evt_px_cat of Array.from($scope.event.prices)) {
          $scope.reserve.nbPlaces[evt_px_cat.id] = __range__(0, $scope.event.nb_free_places, true)
          $scope.reserve.tickets[evt_px_cat.id] = 0
        }

        return $scope.event.offered = false
      }
    }

    // #
    // Open a modal window which trigger the stripe payment process
    // @param reservation {Object} to book
    // #
    var payByStripe = reservation =>
      $uibModal.open({
        templateUrl: '<%= asset_path "stripe/payment_modal.html" %>',
        size: 'md',
        resolve: {
          reservation () {
            return reservation
          },
          price () {
            return Price.compute(mkRequestParams(reservation, $scope.coupon.applied)).$promise
          },
          wallet () {
            return Wallet.getWalletByUser({ user_id: reservation.user_id }).$promise
          },
          cgv () {
            return CustomAsset.get({ name: 'cgv-file' }).$promise
          },
          objectToPay () {
            return {
              eventToReserve: $scope.event,
              reserve: $scope.reserve,
              member: $scope.ctrl.member
            }
          },
          coupon () {
            return $scope.coupon.applied
          }
        },
        controller: ['$scope', '$uibModalInstance', '$state', 'reservation', 'price', 'cgv', 'Auth', 'Reservation', 'growl', 'wallet', 'helpers', '$filter', 'coupon',
          function ($scope, $uibModalInstance, $state, reservation, price, cgv, Auth, Reservation, growl, wallet, helpers, $filter, coupon) {
            // User's wallet amount
            $scope.walletAmount = wallet.amount

            // Price
            $scope.amount = helpers.getAmountToPay(price.price, wallet.amount)

            // CGV
            $scope.cgv = cgv.custom_asset

            // Reservation
            $scope.reservation = reservation

            // Used in wallet info template to interpolate some translations
            $scope.numberFilter = $filter('number')

            // Callback for the stripe payment authorization
            return $scope.payment = function (status, response) {
              if (response.error) {
                return growl.error(response.error.message)
              } else {
                $scope.attempting = true
                $scope.reservation.card_token = response.id
                return Reservation.save(mkRequestParams($scope.reservation, coupon), reservation => $uibModalInstance.close(reservation)
                  , function (response) {
                    $scope.alerts = []
                    $scope.alerts.push({
                      msg: response.data.card[0],
                      type: 'danger'
                    })
                    return $scope.attempting = false
                  })
              }
            }
          }
        ] })
        .result['finally'](null).then(reservation => afterPayment(reservation))

    // #
    // Open a modal window which trigger the local payment process
    // @param reservation {Object} to book
    // #
    var payOnSite = reservation =>
      $uibModal.open({
        templateUrl: '<%= asset_path "shared/valid_reservation_modal.html" %>',
        size: 'sm',
        resolve: {
          reservation () {
            return reservation
          },
          price () {
            return Price.compute(mkRequestParams(reservation, $scope.coupon.applied)).$promise
          },
          wallet () {
            return Wallet.getWalletByUser({ user_id: reservation.user_id }).$promise
          },
          coupon () {
            return $scope.coupon.applied
          }
        },
        controller: ['$scope', '$uibModalInstance', '$state', 'reservation', 'price', 'Auth', 'Reservation', 'wallet', 'helpers', '$filter', 'coupon',
          function ($scope, $uibModalInstance, $state, reservation, price, Auth, Reservation, wallet, helpers, $filter, coupon) {
            // User's wallet amount
            $scope.walletAmount = wallet.amount

            // Price
            $scope.price = price.price

            // price to pay
            $scope.amount = helpers.getAmountToPay(price.price, wallet.amount)

            // Reservation
            $scope.reservation = reservation

            // Used in wallet info template to interpolate some translations
            $scope.numberFilter = $filter('number')

            // Button label
            if ($scope.amount > 0) {
              $scope.validButtonName = _t('confirm_payment_of_html', { ROLE: $scope.currentUser.role, AMOUNT: $filter('currency')($scope.amount) }, 'messageformat')
            } else {
              if ((price.price > 0) && ($scope.walletAmount === 0)) {
                $scope.validButtonName = _t('confirm_payment_of_html', { ROLE: $scope.currentUser.role, AMOUNT: $filter('currency')(price.price) }, 'messageformat')
              } else {
                $scope.validButtonName = _t('confirm')
              }
            }

            // Callback to validate the payment
            $scope.ok = function () {
              $scope.attempting = true
              return Reservation.save(mkRequestParams($scope.reservation, coupon), function (reservation) {
                $uibModalInstance.close(reservation)
                return $scope.attempting = true
              }
              , function (response) {
                $scope.alerts = []
                angular.forEach(response, (v, k) =>
                  angular.forEach(v, err =>
                    $scope.alerts.push({
                      msg: k + ': ' + err,
                      type: 'danger'
                    })
                  )
                )
                return $scope.attempting = false
              })
            }

            // Callback to cancel the payment
            return $scope.cancel = () => $uibModalInstance.dismiss('cancel')
          }
        ] })
        .result['finally'](null).then(reservation => afterPayment(reservation))

    // #
    // What to do after the payment was successful
    // @param resveration {Object} booked reservation
    // #
    var afterPayment = function (reservation) {
      $scope.event.nb_free_places = $scope.event.nb_free_places - reservation.total_booked_seats
      resetEventReserve()
      $scope.reserveSuccess = true
      $scope.coupon.applied = null
      $scope.reservations.push(reservation)
      if ($scope.currentUser.role === 'admin') {
        return $scope.ctrl.member = null
      }
    }

    // # !!! MUST BE CALLED AT THE END of the controller
    return initialize()
  }
])

function __range__ (left, right, inclusive) {
  let range = []
  let ascending = left < right
  let end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
