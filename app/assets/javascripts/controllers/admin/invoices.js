'use strict'

##
# Controller used in the admin invoices listing page
##
Application.Controllers.controller "InvoicesController", ["$scope", "$state", 'Invoice', 'invoices', '$uibModal', "growl", "$filter", 'Setting', 'settings', '_t'
, ($scope, $state, Invoice, invoices, $uibModal, growl, $filter, Setting, settings, _t) ->



  ### PRIVATE STATIC CONSTANTS ###

  # number of invoices loaded each time we click on 'load more...'
  INVOICES_PER_PAGE = 20



  ### PUBLIC SCOPE ###

  ## List of all users invoices
  $scope.invoices = invoices

  # Invoices filters
  $scope.searchInvoice =
    date: null
    name: ''
    reference: ''

  # currently displayed page of invoices (search results)
  $scope.page = 1

  # true when all invoices are loaded
  $scope.noMoreResults = false

  ## Default invoices ordering/sorting
  $scope.orderInvoice = '-reference'

  ## Invoices parameters
  $scope.invoice =
    logo: null
    reference:
      model: ''
      help: null
      templateUrl: 'editReference.html'
    code:
      model: ''
      active: true
      templateUrl: 'editCode.html'
    number:
      model: ''
      help: null
      templateUrl: 'editNumber.html'
    VAT:
      rate: 19.6
      active: false
      templateUrl: 'editVAT.html'
    text:
      content: ''
    legals:
      content: ''

  ## Placeholding date for the invoice creation
  $scope.today = moment()

  ## Placeholding date for the reservation begin
  $scope.inOneWeek = moment().add(1, 'week').startOf('hour')

  ## Placeholding date for the reservation end
  $scope.inOneWeekAndOneHour = moment().add(1, 'week').add(1, 'hour').startOf('hour')



  ##
  # Change the invoices ordering criterion to the one provided
  # @param orderBy {string} ordering criterion
  ##
  $scope.setOrderInvoice = (orderBy)->
    if $scope.orderInvoice == orderBy
      $scope.orderInvoice = '-'+orderBy
    else
      $scope.orderInvoice = orderBy

    resetSearchInvoice()
    invoiceSearch()



  ##
  # Open a modal window asking the admin the details to refund the user about the provided invoice
  # @param invoice {Object} invoice inherited from angular's $resource
  ##
  $scope.generateAvoirForInvoice = (invoice)->
    # open modal
    modalInstance = $uibModal.open
      templateUrl: '<%= asset_path "admin/invoices/avoirModal.html" %>'
      controller: 'AvoirModalController'
      resolve:
        invoice: -> invoice

    # once done, update the invoice model and inform the admin
    modalInstance.result.then (res) ->
      $scope.invoices.unshift res.avoir
      Invoice.get {id: invoice.id}, (data) ->
        invoice.has_avoir = data.has_avoir
        growl.success(_t('refund_invoice_successfully_created'))



  ##
  # Generate an invoice reference sample from the parametrized model
  # @returns {string} invoice reference sample
  ##
  $scope.mkReference = ->
    sample = $scope.invoice.reference.model
    if sample
      # invoice number per day (dd..dd)
      sample = sample.replace(/d+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(2, match.length)
      )
      # invoice number per month (mm..mm)
      sample = sample.replace(/m+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(12, match.length)
      )
      # invoice number per year (yy..yy)
      sample = sample.replace(/y+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(8, match.length)
      )
      # date information
      sample = sample.replace(/[YMD]+(?![^\[]*])/g, (match, offset, string) ->
        $scope.today.format(match)
      )
      # information about online selling (X[text])
      sample = sample.replace(/X\[([^\]]+)\]/g, (match, p1, offset, string) ->
        p1
      )
      # information about wallet (W[text]) - does not apply here
      sample = sample.replace(/W\[([^\]]+)\]/g, "")
      # information about refunds (R[text]) - does not apply here
      sample = sample.replace(/R\[([^\]]+)\]/g, "")
    sample


  ##
  # Generate an order nmuber sample from the parametrized model
  # @returns {string} invoice reference sample
  ##
  $scope.mkNumber = ->
    sample = $scope.invoice.number.model
    if sample
      # global order number (nn..nn)
      sample = sample.replace(/n+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(327, match.length)
      )
      # order number per year (yy..yy)
      sample = sample.replace(/y+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(8, match.length)
      )
      # order number per month (mm..mm)
      sample = sample.replace(/m+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(12, match.length)
      )
      # order number per day (dd..dd)
      sample = sample.replace(/d+(?![^\[]*])/g, (match, offset, string) ->
        padWithZeros(2, match.length)
      )
      # date information
      sample = sample.replace(/[YMD]+(?![^\[]*])/g, (match, offset, string) ->
        $scope.today.format(match)
      )
    sample



  ##
  # Open a modal dialog allowing the user to edit the invoice reference generation template
  ##
  $scope.openEditReference = ->
    modalInstance = $uibModal.open
      animation: true,
      templateUrl: $scope.invoice.reference.templateUrl,
      size: 'lg',
      resolve:
        model: ->
          $scope.invoice.reference.model
      controller: ($scope, $uibModalInstance, model) ->
        $scope.model = model
        $scope.ok = ->
          $uibModalInstance.close($scope.model)
        $scope.cancel = ->
          $uibModalInstance.dismiss('cancel')

    modalInstance.result.then (model) ->
      Setting.update { name: 'invoice_reference' }, { value: model }, (data)->
        $scope.invoice.reference.model = model
        growl.success(_t('invoice_reference_successfully_saved'))
      , (error)->
        growl.error(_t('an_error_occurred_while_saving_invoice_reference'))
        console.error(error)




  ##
  # Open a modal dialog allowing the user to edit the invoice code
  ##
  $scope.openEditCode = ->
    modalInstance = $uibModal.open
      animation: true,
      templateUrl: $scope.invoice.code.templateUrl,
      size: 'lg',
      resolve:
        model: ->
          $scope.invoice.code.model
        active: ->
          $scope.invoice.code.active
      controller: ($scope, $uibModalInstance, model, active) ->
        $scope.codeModel = model
        $scope.isSelected = active


        $scope.ok = ->
          $uibModalInstance.close({model: $scope.codeModel, active: $scope.isSelected})
        $scope.cancel = ->
          $uibModalInstance.dismiss('cancel')

    modalInstance.result.then (result) ->
      Setting.update { name: 'invoice_code-value' }, { value: result.model }, (data)->
        $scope.invoice.code.model = result.model
        if result.active
          growl.success(_t('invoicing_code_succesfully_saved'))
      , (error)->
        growl.error(_t('an_error_occurred_while_saving_the_invoicing_code'))
        console.error(error)

      Setting.update { name: 'invoice_code-active' }, { value: if result.active then "true" else "false" }, (data)->
        $scope.invoice.code.active = result.active
        if result.active
          growl.success(_t('code_successfully_activated'))
        else
          growl.success(_t('code_successfully_disabled'))
      , (error)->
        growl.error(_t('an_error_occurred_while_activating_the_invoicing_code'))
        console.error(error)




  ##
  # Open a modal dialog allowing the user to edit the invoice number
  ##
  $scope.openEditInvoiceNb = ->
    modalInstance = $uibModal.open
      animation: true,
      templateUrl: $scope.invoice.number.templateUrl,
      size: 'lg',
      resolve:
        model: ->
          $scope.invoice.number.model
      controller: ($scope, $uibModalInstance, model) ->
        $scope.model = model
        $scope.ok = ->
          $uibModalInstance.close($scope.model)
        $scope.cancel = ->
          $uibModalInstance.dismiss('cancel')

    modalInstance.result.then (model) ->
      Setting.update { name: 'invoice_order-nb' }, { value: model }, (data)->
        $scope.invoice.number.model = model
        growl.success(_t('order_number_successfully_saved'))
      , (error)->
        growl.error(_t('an_error_occurred_while_saving_the_order_number'))
        console.error(error)




  ##
  # Open a modal dialog allowing the user to edit the VAT parameters for the invoices
  # The VAT can be disabled and its rate can be configured
  ##
  $scope.openEditVAT = ->
    modalInstance = $uibModal.open
      animation: true,
      templateUrl: $scope.invoice.VAT.templateUrl,
      size: 'lg',
      resolve:
        rate: ->
          $scope.invoice.VAT.rate
        active: ->
          $scope.invoice.VAT.active
      controller: ($scope, $uibModalInstance, rate, active) ->
        $scope.rate = rate
        $scope.isSelected = active


        $scope.ok = ->
          $uibModalInstance.close({rate: $scope.rate, active: $scope.isSelected})
        $scope.cancel = ->
          $uibModalInstance.dismiss('cancel')

    modalInstance.result.then (result) ->
      Setting.update { name: 'invoice_VAT-rate' }, { value: result.rate+"" }, (data)->
        $scope.invoice.VAT.rate = result.rate
        if result.active
          growl.success(_t('VAT_rate_successfully_saved'))
      , (error)->
        growl.error(_t('an_error_occurred_while_saving_the_VAT_rate'))
        console.error(error)

      Setting.update { name: 'invoice_VAT-active' }, { value: if result.active then "true" else "false" }, (data)->
        $scope.invoice.VAT.active = result.active
        if result.active
          growl.success(_t('VAT_successfully_activated'))
        else
          growl.success(_t('VAT_successfully_disabled'))
      , (error)->
        growl.error(_t('an_error_occurred_while_activating_the_VAT'))
        console.error(error)



  ##
  # Callback to save the value of the text zone when editing is done
  ##
  $scope.textEditEnd = (event) ->
    parsed = parseHtml($scope.invoice.text.content)
    Setting.update { name: 'invoice_text' }, { value: parsed }, (data)->
      $scope.invoice.text.content = parsed
      growl.success(_t('text_successfully_saved'))
    , (error)->
      growl.error(_t('an_error_occurred_while_saving_the_text'))
      console.error(error)



  ##
  # Callback to save the value of the legal information zone when editing is done
  ##
  $scope.legalsEditEnd = (event) ->
    parsed = parseHtml($scope.invoice.legals.content)
    Setting.update { name: 'invoice_legals' }, { value: parsed }, (data)->
      $scope.invoice.legals.content = parsed
      growl.success(_t('address_and_legal_information_successfully_saved'))
    , (error)->
      growl.error(_t('an_error_occurred_while_saving_the_address_and_the_legal_information'))
      console.error(error)



  ##
  # Callback when any of the filters changes.
  # Full reload the results list
  ##
  $scope.handleFilterChange = ->
    resetSearchInvoice()
    invoiceSearch()



  ##
  # Callback for the 'load more' button.
  # Will load the next results of the current search, if any
  ##
  $scope.showNextInvoices = ->
    $scope.page += 1
    invoiceSearch(true)



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    if (!invoices[0] || invoices[0].maxInvoices <= $scope.invoices.length)
      $scope.noMoreResults = true

    # retrieve settings from the DB through the API
    $scope.invoice.legals.content = settings['invoice_legals']
    $scope.invoice.text.content = settings['invoice_text']
    $scope.invoice.VAT.rate = parseFloat(settings['invoice_VAT-rate'])
    $scope.invoice.VAT.active = (settings['invoice_VAT-active'] == "true")
    $scope.invoice.number.model = settings['invoice_order-nb']
    $scope.invoice.code.model = settings['invoice_code-value']
    $scope.invoice.code.active = (settings['invoice_code-active'] == "true")
    $scope.invoice.reference.model = settings['invoice_reference']
    $scope.invoice.logo =
      filetype: 'image/png'
      filename: 'logo.png'
      base64: settings['invoice_logo']

    # Watch the logo, when a change occurs, save it
    $scope.$watch 'invoice.logo', ->
      if $scope.invoice.logo and $scope.invoice.logo.filesize
        Setting.update { name: 'invoice_logo' }, { value: $scope.invoice.logo.base64 }, (data)->
          growl.success(_t('logo_successfully_saved'))
        , (error)->
          growl.error(_t('an_error_occurred_while_saving_the_logo'))
          console.error(error)



  ##
  # Output the given integer with leading zeros. If the given value is longer than the given
  # length, it will be truncated.
  # @param value {number} the integer to pad
  # @param length {number} the length of the resulting string.
  ##
  padWithZeros = (value, length) ->
    (1e15+value+"").slice(-length)



  ##
  # Remove every unsupported html tag from the given html text (like <p>, <span>, ...).
  # The supported tags are <b>, <u>, <i> and <br>.
  # @param html {string} single line html text
  # @return {string} multi line simplified html text
  ##
  parseHtml = (html) ->
    html = html.replace(/<\/?(\w+)((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>/g, (match, p1, offset, string) ->
      if p1 in ['b', 'u', 'i', 'br']
        match
      else
        ''
    )



  ##
  # Reinitialize the context of invoices' search to display new results set
  ##
  resetSearchInvoice = ->
    $scope.page = 1
    $scope.noMoreResults = false



  ##
  # Run a search query with the current parameters set concerning invoices, then affect or concat the results
  # to $scope.invoices
  # @param concat {boolean} if true, the result will be append to $scope.invoices instead of being affected
  ##
  invoiceSearch = (concat) ->
    Invoice.list {
      query:
        number: $scope.searchInvoice.reference
        customer: $scope.searchInvoice.name
        date: $scope.searchInvoice.date
        order_by: $scope.orderInvoice
        page: $scope.page
        size: INVOICES_PER_PAGE
    }, (invoices) ->
      if concat
        $scope.invoices = $scope.invoices.concat(invoices)
      else
        $scope.invoices = invoices

      if (!invoices[0] || invoices[0].maxInvoices <= $scope.invoices.length)
        $scope.noMoreResults = true



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used in the invoice refunding modal window
##
Application.Controllers.controller 'AvoirModalController', ["$scope", "$uibModalInstance", "invoice", "Invoice", "growl", '_t'
, ($scope, $uibModalInstance, invoice, Invoice, growl, _t) ->



  ### PUBLIC SCOPE ###

  ## invoice linked to the current refund
  $scope.invoice = invoice

  ## Associative array containing invoice_item ids associated with boolean values
  $scope.partial = {}

  ## Default refund parameters
  $scope.avoir =
    invoice_id: invoice.id
    subscription_to_expire: false
    invoice_items_ids: []

  ## Possible refunding methods
  $scope.avoirModes = [
    {name: _t('none'), value: 'none'}
    {name: _t('by_cash'), value: 'cash'}
    {name: _t('by_cheque'), value: 'cheque'}
    {name: _t('by_transfer'), value: 'transfer'}
    {name: _t('by_wallet'), value: 'wallet'}
  ]

  ## If a subscription was took with the current invoice, should it be canceled or not
  $scope.subscriptionExpireOptions = {}
  $scope.subscriptionExpireOptions[_t('yes')] = true
  $scope.subscriptionExpireOptions[_t('no')] = false

  ## AngularUI-Bootstrap datepicker parameters to define when to refund
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    options:
      startingDay: Fablab.weekStartingDay



  ##
  # Callback to open the datepicker
  ##
  $scope.openDatePicker = ($event) ->
    $event.preventDefault()
    $event.stopPropagation()
    $scope.datePicker.opened = true



  ##
  # Validate the refunding and generate a refund invoice
  ##
  $scope.ok = ->
    # check that at least 1 element of the invoice is refunded
    $scope.avoir.invoice_items_ids = []
    for itemId, refundItem of $scope.partial
      $scope.avoir.invoice_items_ids.push(parseInt(itemId)) if refundItem

    if $scope.avoir.invoice_items_ids.length is 0
      growl.error(_t('you_must_select_at_least_one_element_to_create_a_refund'))
    else
      Invoice.save {avoir: $scope.avoir}, (avoir) ->
        # success
        $uibModalInstance.close({avoir:avoir, invoice:$scope.invoice})
      , (err) ->
        # failed
        growl.error(_t('unable_to_create_the_refund'))



  ##
  # Cancel the refund, dismiss the modal window
  ##
  $scope.cancel = ->
    $uibModalInstance.dismiss('cancel')



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    ## if the invoice was payed with stripe, allow to refund through stripe
    Invoice.get {id: invoice.id}, (data) ->
      $scope.invoice = data
      # default : all elements of the invoice are refund
      for item in data.items
        $scope.partial[item.id] = (typeof item.avoir_item_id isnt 'number')

    if invoice.stripe
      $scope.avoirModes.push {name: _t('online_payment'), value: 'stripe'}


  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]
