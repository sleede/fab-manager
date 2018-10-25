Application.Directives.directive 'cart', [ '$rootScope', '$uibModal', 'dialogs', 'growl', 'Auth', 'Price', 'Wallet', 'CustomAsset', 'Slot', 'helpers', '_t'
, ($rootScope, $uibModal, dialogs, growl, Auth, Price, Wallet, CustomAsset, Slot, helpers, _t) ->
  {
    restrict: 'E'
    scope:
      slot: '='
      slotSelectionTime: '='
      events: '='
      user: '='
      modePlans: '='
      plan: '='
      planSelectionTime: '='
      settings: '='
      onSlotAddedToCart: '='
      onSlotRemovedFromCart: '='
      onSlotStartToModify: '='
      onSlotModifyDestination: '='
      onSlotModifySuccess: '='
      onSlotModifyCancel: '='
      onSlotModifyUnselect: '='
      onSlotCancelSuccess: '='
      afterPayment: '='
      reservableId: '@'
      reservableType: '@'
      reservableName: '@'
      limitToOneSlot: '@'
    templateUrl: '<%= asset_path "shared/_cart.html" %>'
    link: ($scope, element, attributes) ->
      ## will store the user's plan if he choosed to buy one
      $scope.selectedPlan = null

      ## total amount of the bill to pay
      $scope.amountTotal = 0

      ## total amount of the elements in the cart, without considering any coupon
      $scope.totalNoCoupon = 0

      ## Discount coupon to apply to the basket, if any
      $scope.coupon =
        applied: null

      ## Global config: is the user authorized to change his bookings slots?
      $scope.enableBookingMove = ($scope.settings.booking_move_enable == "true")

      ## Global config: delay in hours before a booking while changing the booking slot is forbidden
      $scope.moveBookingDelay = parseInt($scope.settings.booking_move_delay)

      ## Global config: is the user authorized to cancel his bookings?
      $scope.enableBookingCancel = ($scope.settings.booking_cancel_enable == "true")

      ## Global config: delay in hours before a booking while the cancellation is forbidden
      $scope.cancelBookingDelay = parseInt($scope.settings.booking_cancel_delay)



      ##
      # Add the provided slot to the shopping cart (state transition from free to 'about to be reserved')
      # and increment the total amount of the cart if needed.
      # @param slot {Object} fullCalendar event object
      ##
      $scope.validateSlot = (slot)->
        slot.isValid = true
        updateCartPrice()



      ##
      # Remove the provided slot from the shopping cart (state transition from 'about to be reserved' to free)
      # and decrement the total amount of the cart if needed.
      # @param slot {Object} fullCalendar event object
      # @param index {number} index of the slot in the reservation array
      # @param [event] {Object} see https://docs.angularjs.org/guide/expression#-event-
      ##
      $scope.removeSlot = (slot, index, event)->
        event.preventDefault() if event
        $scope.events.reserved.splice(index, 1)
        # if is was the last slot, we remove any plan from the cart
        if $scope.events.reserved.length == 0
          $scope.selectedPlan = null
          $scope.plan = null
          $scope.modePlans = false
        $scope.onSlotRemovedFromCart(slot) if typeof $scope.onSlotRemovedFromCart == 'function'
        updateCartPrice()



      ##
      # Checks that every selected slots were added to the shopping cart. Ie. will return false if
      # any checked slot was not validated by the user.
      ##
      $scope.isSlotsValid = ->
        isValid = true
        angular.forEach $scope.events.reserved, (m)->
          isValid = false if !m.isValid
        isValid



      ##
      # Switch the user's view from the reservation agenda to the plan subscription
      ##
      $scope.showPlans = ->
        # first, we ensure that a user was selected (admin) or logged (member)
        if Object.keys($scope.user).length > 0
          $scope.modePlans = true
        else
          # otherwise we alert, this error musn't occur when the current user hasn't the admin role
          growl.error(_t('cart.please_select_a_member_first'))


      ##
      # Validates the shopping chart and redirect the user to the payment step
      ##
      $scope.payCart = ->
        # first, we check that a user was selected
        if Object.keys($scope.user).length > 0
          reservation = mkReservation($scope.user, $scope.events.reserved, $scope.selectedPlan)

          Wallet.getWalletByUser {user_id: $scope.user.id}, (wallet) ->
            amountToPay = helpers.getAmountToPay($scope.amountTotal, wallet.amount)
            if not $scope.isAdmin() and amountToPay > 0
              payByStripe(reservation)
            else
              if $scope.isAdmin() or amountToPay is 0
                payOnSite(reservation)
        else
          # otherwise we alert, this error musn't occur when the current user is not admin
          growl.error(_t('cart.please_select_a_member_first'))


      ##
      # When modifying an already booked reservation, confirm the modification.
      ##
      $scope.modifySlot = ->
        Slot.update {id: $scope.events.modifiable.id},
          slot:
            start_at: $scope.events.placable.start
            end_at: $scope.events.placable.end
            availability_id: $scope.events.placable.availability_id
        , -> # success
          # -> run the callback
          $scope.onSlotModifySuccess() if typeof $scope.onSlotModifySuccess == 'function'
          # -> set the events as successfully moved (to display a summary)
          $scope.events.moved =
            newSlot: $scope.events.placable
            oldSlot: $scope.events.modifiable
          # -> reset the 'moving' status
          $scope.events.placable = null
          $scope.events.modifiable = null
        , (err) ->  # failure
          growl.error(_t('cart.unable_to_change_the_reservation'))
          console.error(err)



      ##
      # Cancel the current booking modification, reseting the whole process
      # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
      ##
      $scope.cancelModifySlot = (event) ->
        event.preventDefault() if event
        $scope.onSlotModifyCancel() if typeof $scope.onSlotModifyCancel == 'function'
        $scope.events.placable = null
        $scope.events.modifiable = null



      ##
      # When modifying an already booked reservation, cancel the choice of the new slot
      # @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
      ##
      $scope.removeSlotToPlace = (e)->
        e.preventDefault()
        $scope.onSlotModifyUnselect() if typeof $scope.onSlotModifyUnselect == 'function'
        $scope.events.placable = null



      ##
      # Checks if $scope.events.modifiable and $scope.events.placable have tag incompatibilities
      # @returns {boolean} true in case of incompatibility
      ##
      $scope.tagMissmatch = ->
        return false if $scope.events.placable.tag_ids.length == 0
        for tag in $scope.events.modifiable.tags
          if tag.id not in $scope.events.placable.tag_ids
            return true
        false



      ##
      # Check if the currently logged user has teh 'admin' role?
      # @returns {boolean}
      ##
      $scope.isAdmin = ->
        $rootScope.currentUser and $rootScope.currentUser.role is 'admin'



      ### PRIVATE SCOPE ###

      ##
      # Kind of constructor: these actions will be realized first when the directive is loaded
      ##
      initialize = ->
        # What the binded slot
        $scope.$watch 'slotSelectionTime', (newValue, oldValue) ->
          if newValue != oldValue
            slotSelectionChanged()
        $scope.$watch 'user', (newValue, oldValue) ->
          if newValue != oldValue
            resetCartState()
            updateCartPrice()
        $scope.$watch 'planSelectionTime', (newValue, oldValue) ->
          if newValue != oldValue
            planSelectionChanged()
        # watch when a coupon is applied to re-compute the total price
        $scope.$watch 'coupon.applied', (newValue, oldValue) ->
          unless newValue == null and oldValue == null
            updateCartPrice()



      ##
      # Callback triggered when the selected slot changed
      ##
      slotSelectionChanged = ->
        if $scope.slot
          if not $scope.slot.is_reserved and not $scope.events.modifiable and not $scope.slot.is_completed
            # slot is not reserved and we are not currently modifying a slot
            # -> can be added to cart or removed if already present
            index = $scope.events.reserved.indexOf($scope.slot)
            if index == -1
              if $scope.limitToOneSlot is 'true' and $scope.events.reserved[0]
                # if we limit the number of slots in the cart to 1, and there is already
                # a slot in the cart, we remove it before adding the new one
                $scope.removeSlot($scope.events.reserved[0], 0)
              # slot is not in the cart, so we add it
              $scope.events.reserved.push $scope.slot
              $scope.onSlotAddedToCart() if typeof $scope.onSlotAddedToCart == 'function'
            else
              # slot is in the cart, remove it
              $scope.removeSlot($scope.slot, index)
            # in every cases, because a new reservation has started, we reset the cart content
            resetCartState()
            # finally, we update the prices
            updateCartPrice()
          else if !$scope.slot.is_reserved and !$scope.slot.is_completed and $scope.events.modifiable
            # slot is not reserved but we are currently modifying a slot
            # -> we request the calender to change the rendering
            $scope.onSlotModifyUnselect() if typeof $scope.onSlotModifyUnselect == 'function'
            # -> then, we re-affect the destination slot
            if !$scope.events.placable or $scope.events.placable._id != $scope.slot._id
              $scope.events.placable = $scope.slot
            else
              $scope.events.placable = null
          else if $scope.slot.is_reserved and $scope.events.modifiable and $scope.slot.is_reserved._id == $scope.events.modifiable._id
            # slot is reserved and currently modified
            # -> we cancel the modification
            $scope.cancelModifySlot()
          else if $scope.slot.is_reserved and (slotCanBeModified($scope.slot) or slotCanBeCanceled($scope.slot)) and !$scope.events.modifiable and $scope.events.reserved.length == 0
            # slot is reserved and is ok to be modified or cancelled
            # but we are not currently running a modification or having any slots in the cart
            # -> first the affect the modification/cancellation rights attributes to the current slot
            resetCartState()
            $scope.slot.movable = slotCanBeModified($scope.slot)
            $scope.slot.cancelable = slotCanBeCanceled($scope.slot)
            # -> then, we open a dialog to ask to the user to choose an action
            dialogs.confirm
              templateUrl: '<%= asset_path "shared/confirm_modify_slot_modal.html" %>'
              resolve:
                object: -> $scope.slot
            , (type) ->
              # the user has choosen an action, so we proceed
              if type == 'move'
                $scope.onSlotStartToModify() if typeof $scope.onSlotStartToModify == 'function'
                $scope.events.modifiable = $scope.slot
              else if type == 'cancel'
                dialogs.confirm
                  resolve:
                    object: ->
                      title: _t('cart.confirmation_required')
                      msg: _t('cart.do_you_really_want_to_cancel_this_reservation')
                , -> # cancel confirmed
                  Slot.cancel {id: $scope.slot.id}, -> # successfully canceled
                    growl.success _t('cart.reservation_was_cancelled_successfully')
                    $scope.onSlotCancelSuccess() if typeof $scope.onSlotCancelSuccess == 'function'
                  , -> # error while canceling
                    growl.error _t('cart.cancellation_failed')



      ##
      # Reset the parameters that may lead to a wrong price but leave the content (events added to cart)
      ##
      resetCartState = ->
        $scope.selectedPlan = null
        $scope.coupon.applied = null
        $scope.events.moved = null
        $scope.events.paid = []
        $scope.events.modifiable = null
        $scope.events.placable = null



      ##
      # Determines if the provided booked slot is able to be modified by the user.
      # @param slot {Object} fullCalendar event object
      ##
      slotCanBeModified = (slot)->
        return true if $scope.isAdmin()
        slotStart = moment(slot.start)
        now = moment()
        if slot.can_modify and $scope.enableBookingMove and slotStart.diff(now, "hours") >= $scope.moveBookingDelay
          return true
        else
          return false



      ##
      # Determines if the provided booked slot is able to be canceled by the user.
      # @param slot {Object} fullCalendar event object
      ##
      slotCanBeCanceled = (slot) ->
        return true if $scope.isAdmin()
        slotStart = moment(slot.start)
        now = moment()
        if slot.can_modify and $scope.enableBookingCancel and slotStart.diff(now, "hours") >= $scope.cancelBookingDelay
          return true
        else
          return false



      ##
      # Callback triggered when the selected slot changed
      ##
      planSelectionChanged = ->
        if Auth.isAuthenticated()
          if $scope.selectedPlan != $scope.plan
            $scope.selectedPlan = $scope.plan
          else
            $scope.selectedPlan = null
          updateCartPrice()
        else
          $rootScope.login null, ->
            $scope.selectedPlan = $scope.plan
            updateCartPrice()


      ##
      # Update the total price of the current selection/reservation
      ##
      updateCartPrice = ->
        if Object.keys($scope.user).length > 0
          r = mkReservation($scope.user, $scope.events.reserved, $scope.selectedPlan)
          Price.compute mkRequestParams(r, $scope.coupon.applied), (res) ->
            $scope.amountTotal = res.price
            $scope.totalNoCoupon = res.price_without_coupon
            setSlotsDetails(res.details)
        else
          # otherwise we alert, this error musn't occur when the current user is not admin
          growl.warning(_t('cart.please_select_a_member_first'))
          $scope.amountTotal = null


      setSlotsDetails = (details) ->
        angular.forEach $scope.events.reserved, (slot) ->
          angular.forEach details.slots, (s) ->
            if moment(s.start_at).isSame(slot.start)
              slot.promo = s.promo
              slot.price = s.price


      ##
      # Format the parameters expected by /api/prices/compute or /api/reservations and return the resulting object
      # @param reservation {Object} as returned by mkReservation()
      # @param coupon {Object} Coupon as returned from the API
      # @return {{reservation:Object, coupon_code:string}}
      ##
      mkRequestParams = (reservation, coupon) ->
        params =
          reservation: reservation
          coupon_code: (coupon.code if coupon)

        params



      ##
      # Create an hash map implementing the Reservation specs
      # @param member {Object} User as retreived from the API: current user / selected user if current is admin
      # @param slots {Array<Object>} Array of fullCalendar events: slots selected on the calendar
      # @param [plan] {Object} Plan as retrived from the API: plan to buy with the current reservation
      # @return {{user_id:Number, reservable_id:Number, reservable_type:String, slots_attributes:Array<Object>, plan_id:Number|null}}
      ##
      mkReservation = (member, slots, plan = null) ->
        reservation =
          user_id: member.id
          reservable_id: $scope.reservableId
          reservable_type: $scope.reservableType
          slots_attributes: []
          plan_id: (plan.id if plan)
        angular.forEach slots, (slot, key) ->
          reservation.slots_attributes.push
            start_at: slot.start
            end_at: slot.end
            availability_id: slot.availability_id
            offered: slot.offered || false

        reservation



      ##
      # Open a modal window that allows the user to process a credit card payment for his current shopping cart.
      ##
      payByStripe = (reservation) ->
        $uibModal.open
          templateUrl: '<%= asset_path "stripe/payment_modal.html" %>'
          size: 'md'
          resolve:
            reservation: ->
              reservation
            price: ->
              Price.compute(mkRequestParams(reservation, $scope.coupon.applied)).$promise
            wallet: ->
              Wallet.getWalletByUser({user_id: reservation.user_id}).$promise
            cgv: ->
              CustomAsset.get({name: 'cgv-file'}).$promise
            coupon: ->
              $scope.coupon.applied
          controller: ['$scope', '$uibModalInstance', '$state', 'reservation', 'price', 'cgv', 'Auth', 'Reservation', 'wallet', 'helpers', '$filter', 'coupon',
            ($scope, $uibModalInstance, $state, reservation, price, cgv, Auth, Reservation, wallet, helpers, $filter, coupon) ->
              # user wallet amount
              $scope.walletAmount = wallet.amount

              # Price
              $scope.amount = helpers.getAmountToPay(price.price, wallet.amount)

              # CGV
              $scope.cgv = cgv.custom_asset

              # Reservation
              $scope.reservation = reservation

              # Used in wallet info template to interpolate some translations
              $scope.numberFilter = $filter('number')

              ##
              # Callback to process the payment with Stripe, triggered on button click
              ##
              $scope.payment = (status, response) ->
                if response.error
                  growl.error(response.error.message)
                else
                  $scope.attempting = true
                  $scope.reservation.card_token = response.id
                  Reservation.save mkRequestParams($scope.reservation, coupon), (reservation) ->
                    $uibModalInstance.close(reservation)
                  , (response)->
                    $scope.alerts = []
                    if response.status == 500
                      $scope.alerts.push
                        msg: response.statusText
                        type: 'danger'
                    else
                      if response.data.card and response.data.card.join('').length > 0
                        $scope.alerts.push
                          msg: response.data.card.join('. ')
                          type: 'danger'
                      else if response.data.payment and response.data.payment.join('').length > 0
                        $scope.alerts.push
                          msg: response.data.payment.join('. ')
                          type: 'danger'
                    $scope.attempting = false
          ]
        .result['finally'](null).then (reservation)->
          afterPayment(reservation)



      ##
      # Open a modal window that allows the user to process a local payment for his current shopping cart (admin only).
      ##
      payOnSite = (reservation) ->
        $uibModal.open
          templateUrl: '<%= asset_path "shared/valid_reservation_modal.html" %>'
          size: 'sm'
          resolve:
            reservation: ->
              reservation
            price: ->
              Price.compute(mkRequestParams(reservation, $scope.coupon.applied)).$promise
            wallet: ->
              Wallet.getWalletByUser({user_id: reservation.user_id}).$promise
            coupon: ->
              $scope.coupon.applied
          controller: ['$scope', '$uibModalInstance', '$state', 'reservation', 'price', 'Auth', 'Reservation', 'wallet', 'helpers', '$filter', 'coupon',
            ($scope, $uibModalInstance, $state, reservation, price, Auth, Reservation, wallet, helpers, $filter, coupon) ->

              # user wallet amount
              $scope.walletAmount = wallet.amount

              # Global price (total of all items)
              $scope.price = price.price

              # Price to pay (wallet deducted)
              $scope.amount = helpers.getAmountToPay(price.price, wallet.amount)

              # Reservation
              $scope.reservation = reservation

              # Used in wallet info template to interpolate some translations
              $scope.numberFilter = $filter('number')

              # Button label
              if $scope.amount > 0
                $scope.validButtonName = _t('cart.confirm_payment_of_html', {ROLE:$rootScope.currentUser.role, AMOUNT:$filter('currency')($scope.amount)}, "messageformat")
              else
                if price.price > 0 and $scope.walletAmount == 0
                  $scope.validButtonName = _t('cart.confirm_payment_of_html', {ROLE:$rootScope.currentUser.role, AMOUNT:$filter('currency')(price.price)}, "messageformat")
                else
                  $scope.validButtonName = _t('confirm')

              ##
              # Callback to process the local payment, triggered on button click
              ##
              $scope.ok = ->
                $scope.attempting = true
                Reservation.save mkRequestParams($scope.reservation, coupon), (reservation) ->
                  $uibModalInstance.close(reservation)
                  $scope.attempting = true
                , (response)->
                  $scope.alerts = []
                  $scope.alerts.push({msg: _t('cart.a_problem_occured_during_the_payment_process_please_try_again_later'), type: 'danger' })
                  $scope.attempting = false
              $scope.cancel = ->
                $uibModalInstance.dismiss('cancel')
          ]
        .result['finally'](null).then (reservation)->
          afterPayment(reservation)



      ##
      # Actions to run after the payment was successfull
      ##
      afterPayment = (reservation) ->
        # we set the cart content as 'paid' to display a summary of the transaction
        $scope.events.paid = $scope.events.reserved
        # we call the external callback if present
        $scope.afterPayment(reservation) if typeof $scope.afterPayment == 'function'
        # we reset the coupon and the cart content and we unselect the slot
        $scope.events.reserved = []
        $scope.coupon.applied = null
        $scope.slot = null
        $scope.selectedPlan = null



      ## !!! MUST BE CALLED AT THE END of the directive
      initialize()
  }
]


