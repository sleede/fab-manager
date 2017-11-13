
### COMMON CODE ###

##
# Provides a set of common callback methods to the $scope parameter. These methods are used
# in the various spaces' admin controllers.
#
# Provides :
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.fileinputClass(v)
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#
# Requires :
#  - $scope.space.space_files_attributes = []
#  - $state (Ui-Router) [ 'app.public.spaces_list' ]
##
class SpacesController
  constructor: ($scope, $state) ->
    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when the upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the spaces list.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.id?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            $scope.alerts.push
              msg: k+': '+err
              type: 'danger'
      else
        $state.go('app.public.spaces_list')

    ##
    # Changes the current user's view, redirecting him to the spaces list
    ##
    $scope.cancel = ->
      $state.go('app.public.spaces_list')

    ##
    # For use with 'ng-class', returns the CSS class name for the uploads previews.
    # The preview may show a placeholder or the content of the file depending on the upload state.
    # @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
    ##
    $scope.fileinputClass = (v)->
      if v
        'fileinput-exists'
      else
        'fileinput-new'

    ##
    # This will create a single new empty entry into the space attachements list.
    ##
    $scope.addFile = ->
      $scope.space.space_files_attributes.push {}

    ##
    # This will remove the given file from the space attachements list. If the file was previously uploaded
    # to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
    # the attachements array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteFile = (file) ->
      index = $scope.space.space_files_attributes.indexOf(file)
      if file.id?
        file._destroy = true
      else
        $scope.space.space_files_attributes.splice(index, 1)



##
# Controller used in the public listing page, allowing everyone to see the list of spaces
##
Application.Controllers.controller 'SpacesController', ['$scope', '$state', 'spacesPromise', ($scope, $state, spacesPromise) ->

  ## Retrieve the list of spaces
  $scope.spaces = spacesPromise

  ##
  # Redirect the user to the space details page
  ##
  $scope.showSpace = (space) ->
    $state.go('app.public.space_show', { id: space.slug })

  ##
  # Callback to book a reservation for the current space
  ##
  $scope.reserveSpace = (space) ->
    $state.go('app.logged.space_reserve', { id: space.slug })


  ## Default: we show only enabled spaces
  $scope.spaceFiltering = 'enabled'

  ## Available options for filtering spaces by status
  $scope.filterDisabled = [
    'enabled',
    'disabled',
    'all',
  ]
]



##
# Controller used in the space creation page (admin)
##
Application.Controllers.controller 'NewSpaceController', ['$scope', '$state', 'CSRF',($scope, $state, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/spaces/"

  ## Form action on the above URL
  $scope.method = "post"

  ## default space parameters
  $scope.space =
    space_files_attributes: []

  ## Using the SpacesController
  new SpacesController($scope, $state)
]


##
# Controller used in the space edition page (admin)
##
Application.Controllers.controller 'EditSpaceController', ['$scope', '$state', '$stateParams', 'spacePromise', 'CSRF',($scope, $state, $stateParams, spacePromise, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/spaces/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = "put"

  ## space to modify
  $scope.space = spacePromise

  ## Using the SpacesController
  new SpacesController($scope, $state)
]

Application.Controllers.controller 'ShowSpaceController', ['$scope', '$state', 'spacePromise', '_t', 'dialogs', 'growl', ($scope, $state, spacePromise, _t, dialogs, growl) ->

  ## Details of the space witch id/slug is provided in the URL
  $scope.space = spacePromise

  ##
  # Callback to book a reservation for the current space
  # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
  ##
  $scope.reserveSpace = (event) ->
    event.preventDefault()
    $state.go('app.logged.space_reserve', { id: $scope.space.slug })

  ##
  # Callback to book a reservation for the current space
  # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
  ##
  $scope.deleteSpace = (event) ->
    event.preventDefault()
    # check the permissions
    if $scope.currentUser.role isnt 'admin'
      console.error _t('space_show.unauthorized_operation')
    else
      dialogs.confirm
        resolve:
          object: ->
            title: _t('space_show.confirmation_required')
            msg: _t('space_show.do_you_really_want_to_delete_this_space')
      , -> # deletion confirmed
        # delete the machine then redirect to the machines listing
        $scope.space.$delete ->
          $state.go('app.public.spaces_list')
        , (error)->
          growl.warning(_t('space_show.the_space_cant_be_deleted_because_it_is_already_reserved_by_some_users'))
]



##
# Controller used in the spaces reservation agenda page.
# This controller is very similar to the machine reservation controller with one major difference: here, there is many places
# per slots.
##

Application.Controllers.controller "ReserveSpaceController", ["$scope", '$stateParams', 'Auth', '$timeout', 'Availability', 'Member', 'availabilitySpacesPromise', 'plansPromise', 'groupsPromise', 'settingsPromise', 'spacePromise', '_t', 'uiCalendarConfig', 'CalendarConfig'
($scope, $stateParams, Auth, $timeout, Availability, Member, availabilitySpacesPromise, plansPromise, groupsPromise, settingsPromise, spacePromise, _t, uiCalendarConfig, CalendarConfig) ->



    ### PRIVATE STATIC CONSTANTS ###

    # Color of the selected event backgound
    SELECTED_EVENT_BG_COLOR = '#ffdd00'

    # Slot free to be booked
    FREE_SLOT_BORDER_COLOR = '<%= AvailabilityHelper::SPACE_COLOR %>'

    # Slot with reservation from current user
    RESERVED_SLOT_BORDER_COLOR = '<%= AvailabilityHelper::IS_RESERVED_BY_CURRENT_USER %>'



    ### PUBLIC SCOPE ###

    ## bind the spaces availabilities with full-Calendar events
    $scope.eventSources = [ { events: availabilitySpacesPromise, textColor: 'black' } ]

    ## the user to deal with, ie. the current user for non-admins
    $scope.ctrl =
      member: {}

    ## list of plans, classified by group
    $scope.plansClassifiedByGroup = []
    for group in groupsPromise
      groupObj = { id: group.id, name: group.name, plans: [] }
      for plan in plansPromise
        groupObj.plans.push(plan) if plan.group_id == group.id
      $scope.plansClassifiedByGroup.push(groupObj)

    ## mapping of fullCalendar events.
    $scope.events =
      reserved: [] # Slots that the user wants to book
      modifiable: null # Slot that the user wants to change
      placable: null # Destination slot for the change
      paid: [] # Slots that were just booked by the user (transaction ok)
      moved: null # Slots that were just moved by the user (change done) -> {newSlot:* oldSlot: *}

    ## the moment when the slot selection changed for the last time, used to trigger changes in the cart
    $scope.selectionTime = null

    ## the last clicked event in the calender
    $scope.selectedEvent = null

    ## indicates the state of the current view : calendar or plans information
    $scope.plansAreShown = false

    ## will store the user's plan if he choosed to buy one
    $scope.selectedPlan = null

    ## the moment when the plan selection changed for the last time, used to trigger changes in the cart
    $scope.planSelectionTime = null

    ## Selected space
    $scope.space = spacePromise

    ## fullCalendar (v2) configuration
    $scope.calendarConfig = CalendarConfig
      minTime: moment.duration(moment(settingsPromise.booking_window_start).format('HH:mm:ss'))
      maxTime: moment.duration(moment(settingsPromise.booking_window_end).format('HH:mm:ss'))
      eventClick: (event, jsEvent, view) ->
        calendarEventClickCb(event, jsEvent, view)
      eventRender: (event, element, view) ->
        eventRenderCb(event, element, view)

    ## Application global settings
    $scope.settings = settingsPromise

    ## Global config: message to the end user concerning the subscriptions rules
    $scope.subscriptionExplicationsAlert = settingsPromise.subscription_explications_alert

    ## Global config: message to the end user concerning the space reservation
    $scope.spaceExplicationsAlert = settingsPromise.space_explications_alert


    ##
    # Change the last selected slot's appearence to looks like 'added to cart'
    ##
    $scope.markSlotAsAdded = ->
      $scope.selectedEvent.backgroundColor = SELECTED_EVENT_BG_COLOR
      updateCalendar()



    ##
    # Change the last selected slot's appearence to looks like 'never added to cart'
    ##
    $scope.markSlotAsRemoved = (slot) ->
      slot.backgroundColor = 'white'
      slot.title = ''
      slot.borderColor = FREE_SLOT_BORDER_COLOR
      slot.id = null
      slot.isValid = false
      slot.is_reserved = false
      slot.can_modify = false
      slot.offered = false
      slot.is_completed = false if slot.is_completed
      updateCalendar()



    ##
    # Callback when a slot was successfully cancelled. Reset the slot style as 'ready to book'
    ##
    $scope.slotCancelled = ->
      $scope.markSlotAsRemoved($scope.selectedEvent)



    ##
    # Change the last selected slot's appearence to looks like 'currently looking for a new destination to exchange'
    ##
    $scope.markSlotAsModifying = ->
      $scope.selectedEvent.backgroundColor = '#eee'
      $scope.selectedEvent.title = _t('space_reserve.i_change')
      updateCalendar()



    ##
    # Change the last selected slot's appearence to looks like 'the slot being exchanged will take this place'
    ##
    $scope.changeModifyTrainingSlot = ->
      if $scope.events.placable
        $scope.events.placable.backgroundColor = 'white'
        $scope.events.placable.title = ''
      if !$scope.events.placable or $scope.events.placable._id != $scope.selectedEvent._id
        $scope.selectedEvent.backgroundColor = '#bbb'
        $scope.selectedEvent.title = _t('space_reserve.i_shift')
      updateCalendar()


    ##
    # When modifying an already booked reservation, callback when the modification was successfully done.
    ##
    $scope.modifyTrainingSlot = ->
      $scope.events.placable.title = _t('space_reserve.i_ve_reserved')
      $scope.events.placable.backgroundColor = 'white'
      $scope.events.placable.borderColor = $scope.events.modifiable.borderColor
      $scope.events.placable.id = $scope.events.modifiable.id
      $scope.events.placable.is_reserved = true
      $scope.events.placable.can_modify = true

      $scope.events.modifiable.backgroundColor = 'white'
      $scope.events.modifiable.title = ''
      $scope.events.modifiable.borderColor = FREE_SLOT_BORDER_COLOR
      $scope.events.modifiable.id = null
      $scope.events.modifiable.is_reserved = false
      $scope.events.modifiable.can_modify = false
      $scope.events.modifiable.is_completed = false if $scope.events.modifiable.is_completed

      updateCalendar()



    ##
    # Cancel the current booking modification, reseting the whole process
    ##
    $scope.cancelModifyTrainingSlot = ->
      if $scope.events.placable
        $scope.events.placable.backgroundColor = 'white'
        $scope.events.placable.title = ''
      $scope.events.modifiable.title = _t('space_reserve.i_ve_reserved')
      $scope.events.modifiable.backgroundColor = 'white'

      updateCalendar()



    ##
    # Callback to deal with the reservations of the user selected in the dropdown list instead of the current user's
    # reservations. (admins only)
    ##
    $scope.updateMember = ->
      if $scope.ctrl.member
        Member.get {id: $scope.ctrl.member.id}, (member) ->
          $scope.ctrl.member = member
          Availability.spaces {spaceId: $scope.space.id, member_id: $scope.ctrl.member.id}, (spaces) ->
            uiCalendarConfig.calendars.calendar.fullCalendar 'removeEvents'
            $scope.eventSources.splice(0, 1,
              events: spaces
              textColor: 'black'
            )
      # as the events are re-fetched for the new user, we must re-init the cart
      $scope.events.reserved = []
      $scope.selectedPlan = null
      $scope.plansAreShown = false



    ##
    # Add the provided plan to the current shopping cart
    # @param plan {Object} the plan to subscribe
    ##
    $scope.selectPlan = (plan) ->
      # toggle selected plan
      if $scope.selectedPlan != plan
        $scope.selectedPlan = plan
      else
        $scope.selectedPlan = null
      $scope.planSelectionTime = new Date()



    ##
    # Changes the user current view from the plan subsription screen to the machine reservation agenda
    # @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
    ##
    $scope.doNotSubscribePlan = (e)->
      e.preventDefault()
      $scope.plansAreShown = false
      $scope.selectedPlan = null
      $scope.planSelectionTime = new Date()



    ##
    # Switch the user's view from the reservation agenda to the plan subscription
    ##
    $scope.showPlans = ->
      $scope.plansAreShown = true



    ##
    # Once the reservation is booked (payment process successfully completed), change the event style
    # in fullCalendar, update the user's subscription and free-credits if needed
    # @param reservation {Object}
    ##
    $scope.afterPayment = (reservation)->
      angular.forEach $scope.events.paid, (spaceSlot, key) ->
        spaceSlot.is_reserved = true
        spaceSlot.can_modify = true
        spaceSlot.title = _t('space_reserve.i_ve_reserved')
        spaceSlot.backgroundColor = 'white'
        spaceSlot.borderColor = RESERVED_SLOT_BORDER_COLOR
        updateSpaceSlotId(spaceSlot, reservation)


      if $scope.selectedPlan
        $scope.ctrl.member.subscribed_plan = angular.copy($scope.selectedPlan)
        Auth._currentUser.subscribed_plan = angular.copy($scope.selectedPlan)
        $scope.plansAreShown = false
        $scope.selectedPlan = null
      $scope.ctrl.member.training_credits = angular.copy(reservation.user.training_credits)
      $scope.ctrl.member.machine_credits = angular.copy(reservation.user.machine_credits)
      Auth._currentUser.training_credits = angular.copy(reservation.user.training_credits)
      Auth._currentUser.machine_credits = angular.copy(reservation.user.machine_credits)

      refetchCalendar()



    ##
    # To use as callback in Array.prototype.filter to get only enabled plans
    ##
    $scope.filterDisabledPlans = (plan) ->
      !plan.disabled



    ### PRIVATE SCOPE ###

    ##
    # Kind of constructor: these actions will be realized first when the controller is loaded
    ##
    initialize = ->
      if $scope.currentUser.role isnt 'admin'
        Member.get id: $scope.currentUser.id, (member) ->
          $scope.ctrl.member = member



    ##
    # Triggered when the user clicks on a reservation slot in the agenda.
    # Defines the behavior to adopt depending on the slot status (already booked, free, ready to be reserved ...),
    # the user's subscription (current or about to be took) and the time (the user cannot modify a booked reservation
    # if it's too late).
    # @see http://fullcalendar.io/docs/mouse/eventClick/
    ##
    calendarEventClickCb = (event, jsEvent, view) ->
      $scope.selectedEvent = event
      if $stateParams.id is 'all'
        $scope.training = event.training
      $scope.selectionTime = new Date()




    ##
    # Triggered when fullCalendar tries to graphicaly render an event block.
    # Append the event tag into the block, just after the event title.
    # @see http://fullcalendar.io/docs/event_rendering/eventRender/
    ##
    eventRenderCb = (event, element, view)->
      if $scope.currentUser.role is 'admin' and event.tags.length > 0
        html = ''
        for tag in event.tags
          html += "<span class='label label-success text-white' title='#{tag.name}'>#{tag.name}</span>"
        element.find('.fc-time').append(html)
      return



    ##
    # After payment, update the id of the newly reserved slot with the id returned by the server.
    # This will allow the user to modify the reservation he just booked.
    # @param slot {Object}
    # @param reservation {Object}
    ##
    updateSpaceSlotId = (slot, reservation)->
      angular.forEach reservation.slots, (s)->
        if slot.start_at == slot.start_at
          slot.id = s.id



    ##
    # Update the calendar's display to render the new attributes of the events
    ##
    updateCalendar = ->
      uiCalendarConfig.calendars.calendar.fullCalendar 'rerenderEvents'



    ##
    # Asynchronously fetch the events from the API and refresh the calendar's view with these new events
    ##
    refetchCalendar = ->
      $timeout ->
        uiCalendarConfig.calendars.calendar.fullCalendar 'refetchEvents'
        uiCalendarConfig.calendars.calendar.fullCalendar 'rerenderEvents'



    ## !!! MUST BE CALLED AT THE END of the controller
    initialize()

]