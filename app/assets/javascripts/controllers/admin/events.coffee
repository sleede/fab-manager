'use strict'

### COMMON CODE ###

##
# Provides a set of common properties and methods to the $scope parameter. They are used
# in the various events' admin controllers.
#
# Provides :
#  - $scope.datePicker = {}
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#  - $scope.fileinputClass(v)
#  - $scope.toggleStartDatePicker($event)
#  - $scope.toggleEndDatePicker($event)
#  - $scope.toggleRecurrenceEnd(e)
#  - $scope.addPrice()
#  - $scope.removePrice(price, $event)
#
# Requires :
#  - $scope.event.event_files_attributes = []
#  - $state (Ui-Router) [ 'app.public.events_list' ]
##
class EventsController
  constructor: ($scope, $state) ->

    ## default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker =
      format: Fablab.uibDateFormat
      startOpened: false # default: datePicker is not shown
      endOpened: false
      recurrenceEndOpened: false
      options:
        startingDay: Fablab.weekStartingDay



    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when an upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the project page.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.id?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            $scope.alerts.push({msg: k+': '+err, type: 'danger'})
      else
        $state.go('app.public.events_list')



    ##
    # Changes the user's view to the events list page
    ##
    $scope.cancel = ->
      $state.go('app.public.events_list')



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
    # This will create a single new empty entry into the event's attachements list.
    ##
    $scope.addFile = ->
      $scope.event.event_files_attributes.push {}



    ##
    # This will remove the given file from the event's attachements list. If the file was previously uploaded
    # to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
    # the attachements array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteFile = (file) ->
      index = $scope.event.event_files_attributes.indexOf(file)
      if file.id?
        file._destroy = true
      else
        $scope.event.event_files_attributes.splice(index, 1)



    ##
    # Show/Hide the "start" datepicker (open the drop down/close it)
    ##
    $scope.toggleStartDatePicker = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.datePicker.startOpened = !$scope.datePicker.startOpened



    ##
    # Show/Hide the "end" datepicker (open the drop down/close it)
    ##
    $scope.toggleEndDatePicker = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.datePicker.endOpened = !$scope.datePicker.endOpened



    ##
    # Masks/displays the recurrence pane allowing the admin to set the current event as recursive
    ##
    $scope.toggleRecurrenceEnd = (e)->
      e.preventDefault()
      e.stopPropagation()
      $scope.datePicker.recurrenceEndOpened = !$scope.datePicker.recurrenceEndOpened



    ##
    # Initialize a new price item in the additional prices list
    ##
    $scope.addPrice = ->
      $scope.event.prices.push({
        category: null,
        amount: null,
      })



    ##
    # Remove the price or mark it as 'to delete'
    ##
    $scope.removePrice = (price, event) ->
      event.preventDefault()
      event.stopPropagation()
      if price.id
        price._destroy = true
      else
        index = $scope.event.prices.indexOf(price)
        $scope.event.prices.splice(index, 1)




##
# Controller used in the events listing page (admin view)
##
Application.Controllers.controller "AdminEventsController", ["$scope", "$state", 'dialogs', '$uibModal', 'growl', 'Event', 'Category', 'EventTheme', 'AgeRange', 'PriceCategory', 'eventsPromise', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '_t'
, ($scope, $state, dialogs, $uibModal, growl, Event, Category, EventTheme, AgeRange, PriceCategory, eventsPromise, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, _t) ->



  ### PUBLIC SCOPE ###

  ## By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true

  ## The events displayed on the page
  $scope.events = eventsPromise

  ## Current virtual page
  $scope.page = 1

  ## Temporary datastore for creating new elements
  $scope.inserted =
    category: null
    theme: null
    age_range: null

  ## List of categories for the events
  $scope.categories = categoriesPromise

  ## List of events themes
  $scope.themes = themesPromise

  ## List of age ranges
  $scope.ageRanges = ageRangesPromise

  ## List of price categories for the events
  $scope.priceCategories = priceCategoriesPromise

  ## Default: we display all events (no restriction)
  $scope.eventsScope =
      selected: ''

  ##
  # Adds a bucket of events to the bottom of the page, grouped by month
  ##
  $scope.loadMoreEvents = ->
    $scope.page += 1
    Event.query { page: $scope.page, scope: $scope.eventsScope.selected }, (data)->
      $scope.events = $scope.events.concat data
      paginationCheck(data, $scope.events)


  ##
  # Saves a new element / Update an existing one to the server (form validation callback)
  # @param model {string} model name
  # @param data {Object} element name
  # @param [id] {number} element id, in case of update
  ##
  $scope.saveElement = (model, data, id) ->
    if id?
      getModel(model)[0].update {id: id}, data
    else
      getModel(model)[0].save data, (resp)->
        getModel(model)[1][getModel(model)[1].length-1].id = resp.id



  ##
  # Deletes the element at the specified index
  # @param model {string} model name
  # @param index {number} element index in the $scope[model] array
  ##
  $scope.removeElement = (model, index) ->
    if model == 'category' and getModel(model)[1].length == 1
      growl.error(_t('at_least_one_category_is_required')+' '+_t('unable_to_delete_the_last_one'))
      return false
    if getModel(model)[1][index].related_to > 0
      growl.error(_t('unable_to_delete_ELEMENT_already_in_use_NUMBER_times', {ELEMENT:model, NUMBER:getModel(model)[1][index].related_to}, "messageformat"))
      return false
    dialogs.confirm
      resolve:
        object: ->
          title: _t('confirmation_required')
          msg: _t('do_you_really_want_to_delete_this_ELEMENT', {ELEMENT:model}, "messageformat")
    , -> # delete confirmed
      getModel(model)[0].delete getModel(model)[1][index], null, ->
        getModel(model)[1].splice(index, 1)
      , ->
        growl.error(_t('unable_to_delete_an_error_occured'))



  ##
  # Creates a new empty entry in the $scope[model] array
  # @param model {string} model name
  ##
  $scope.addElement = (model) ->
    $scope.inserted[model] =
      name: ''
      related_to: 0
    getModel(model)[1].push($scope.inserted[model])



  ##
  # Removes the newly inserted but not saved element / Cancel the current element modification
  # @param model {string} model name
  # @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
  # @param index {number} element index in the $scope[model] array
  ##
  $scope.cancelElement = (model, rowform, index) ->
    if getModel(model)[1][index].id?
      rowform.$cancel()
    else
      getModel(model)[1].splice(index, 1)



  ##
  # Open a modal dialog allowing the definition of a new price category.
  # Save it once filled and handle the result.
  ##
  $scope.newPriceCategory = ->
    $uibModal.open
      templateUrl: '<%= asset_path "admin/events/price_form.html" %>'
      size: 'md'
      resolve:
        category: -> {}
      controller: 'PriceCategoryController'
    .result['finally'](null).then (p_cat) ->
      # save the price category to the API
      PriceCategory.save p_cat, (cat) ->
        $scope.priceCategories.push(cat)
        growl.success(_t('price_category_successfully_created'))
      , (err)->
        growl.error(_t('unable_to_add_the_price_category_check_name_already_used'))
        console.error(err)



  ##
  # Update the given price category with the new properties
  # to specify in a modal dialog
  # @param index {number} index of the caterory in the $scope.priceCategories array
  # @param id {number} price category ID, must match the ID of the category at the index specified above
  ##
  $scope.editPriceCategory = (id, index) ->
    if $scope.priceCategories[index].id != id
      growl.error(_t('unexpected_error_occurred_please_refresh'))
    else
      $uibModal.open
        templateUrl: '<%= asset_path "admin/events/price_form.html" %>'
        size: 'md'
        resolve:
          category: -> $scope.priceCategories[index]
        controller: 'PriceCategoryController'
      .result['finally'](null).then (p_cat) ->
        # update the price category to the API
        PriceCategory.update {id: id}, {price_category: p_cat}, (cat) ->
          $scope.priceCategories[index] = cat
          growl.success(_t('price_category_successfully_updated'))
        , (err)->
          growl.error(_t('unable_to_update_the_price_category'))
          console.error(err)



  ##
  # Delete the given price category from the API
  # @param index {number} index of the caterory in the $scope.priceCategories array
  # @param id {number} price category ID, must match the ID of the category at the index specified above
  ##
  $scope.removePriceCategory = (id, index) ->
    if $scope.priceCategories[index].id != id
      growl.error(_t('unexpected_error_occurred_please_refresh'))
    else if $scope.priceCategories[index].events > 0
      growl.error(_t('unable_to_delete_this_price_category_because_it_is_already_used'))
    else
      dialogs.confirm
        resolve:
          object: ->
            title: _t('confirmation_required')
            msg: _t('do_you_really_want_to_delete_this_price_category')
      , -> # delete confirmed
        PriceCategory.remove {id: id}, -> # successfully deleted
          growl.success _t('price_category_successfully_deleted')
          $scope.priceCategories.splice(index, 1)
        , ->
          growl.error _t('price_category_deletion_failed')


  ##
  # Triggered when the admin changes the events filter (all, passed, future).
  # We request the first page of corresponding events to the API
  ##
  $scope.changeScope = ->
    Event.query {page: 1, scope: $scope.eventsScope.selected}, (data)->
      $scope.events = data
      paginationCheck(data, $scope.events)
    $scope.page = 1



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    paginationCheck(eventsPromise, $scope.events)


  ##
  # Check if all events are already displayed OR if the button 'load more events'
  # is required
  # @param lastEvents {Array} last events loaded onto the diplay (ie. last "page")
  # @param events {Array} full list of events displayed on the page (not only the last retrieved)
  ##
  paginationCheck = (lastEvents, events)->
    if lastEvents.length > 0
      if events.length >= lastEvents[0].nb_total_events
        $scope.paginateActive = false
      else
        $scope.paginateActive = true
    else
      $scope.paginateActive = false

  ##
  # Return the model and the datastore matching the given name
  # @param name {string} 'category', 'theme' or 'age_range'
  # @return {[Object, Array]} model and datastore
  ##
  getModel = (name) ->
    switch name
      when 'category' then [Category, $scope.categories]
      when 'theme' then [EventTheme, $scope.themes]
      when 'age_range' then [AgeRange, $scope.ageRanges]
      else [null, []]


  # init the controller (call at the end !)
  initialize()

]



##
# Controller used in the reservations listing page for a specific event
##
Application.Controllers.controller "ShowEventReservationsController", ["$scope", 'eventPromise', 'reservationsPromise', ($scope, eventPromise, reservationsPromise) ->

  ## retrieve the event from the ID provided in the current URL
  $scope.event = eventPromise

  ## list of reservations for the current event
  $scope.reservations = reservationsPromise
]



##
# Controller used in the event creation page
##
Application.Controllers.controller "NewEventController", ["$scope", "$state", 'CSRF', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '_t'
, ($scope, $state, CSRF, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, _t) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/events/"

  ## Form action on the above URL
  $scope.method = 'post'

  ## List of categories for the events
  $scope.categories = categoriesPromise

  ## List of events themes
  $scope.themes = themesPromise

  ## List of age ranges
  $scope.ageRanges = ageRangesPromise

  ## List of availables price's categories
  $scope.priceCategories = priceCategoriesPromise

  ## Default event parameters
  $scope.event =
    event_files_attributes: []
    start_date: new Date()
    end_date: new Date()
    start_time: new Date()
    end_time: new Date()
    all_day: 'false'
    recurrence: 'none'
    category_id: null
    prices: []

  ## Possible types of recurrences for an event
  $scope.recurrenceTypes = [
    {label: _t('none'), value: 'none'},
    {label: _t('every_days'), value: 'day'},
    {label: _t('every_week'), value: 'week'},
    {label: _t('every_month'), value: 'month'},
    {label: _t('every_year'), value: 'year'}
  ]

  ## Using the EventsController
  new EventsController($scope, $state)
]



##
# Controller used in the events edition page
##
Application.Controllers.controller "EditEventController", ["$scope", "$state", "$stateParams", 'CSRF', 'eventPromise', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise'
, ($scope, $state, $stateParams, CSRF, eventPromise, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise) ->

  ### PUBLIC SCOPE ###



  ## API URL where the form will be posted
  $scope.actionUrl = "/api/events/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'put'

  ## Retrieve the event details, in case of error the user is redirected to the events listing
  $scope.event = eventPromise

  ## List of categories for the events
  $scope.categories = categoriesPromise

  ## List of availables price's categories
  $scope.priceCategories = priceCategoriesPromise

  ## List of events themes
  $scope.themes = themesPromise

  ## List of age ranges
  $scope.ageRanges = ageRangesPromise



  ### PRIVATE SCOPE ###



  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    CSRF.setMetaTags()

    # init the dates to JS objects
    $scope.event.start_date = moment($scope.event.start_date).toDate()
    $scope.event.end_date = moment($scope.event.end_date).toDate()

    ## Using the EventsController
    new EventsController($scope, $state)



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]
