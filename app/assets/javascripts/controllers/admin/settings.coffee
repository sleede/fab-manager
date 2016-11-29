'use strict'

Application.Controllers.controller "SettingsController", ["$scope", 'Setting', 'growl', 'settingsPromise', 'cgvFile', 'cguFile', 'logoFile', 'logoBlackFile', 'faviconFile', 'profileImageFile', 'CSRF', '_t'
  ($scope, Setting, growl, settingsPromise, cgvFile, cguFile, logoFile, logoBlackFile, faviconFile, profileImageFile, CSRF, _t) ->



    ### PUBLIC SCOPE ###

    ## timepickers steps configuration
    $scope.timepicker =
      hstep: 1
      mstep: 15

    ## API URL where the upload forms will be posted
    $scope.actionUrl =
        cgu: "/api/custom_assets"
        cgv: "/api/custom_assets"
        logo: "/api/custom_assets"
        logoBlack: "/api/custom_assets"
        favicon: "/api/custom_assets"
        profileImage: "/api/custom_assets"

    ## Form actions on the above URL
    $scope.methods =
        cgu: "post"
        cgv: "post"
        logo: "post"
        logoBlack: "post"
        favicon: "post"
        profileImage: "post"

    ## Are we uploading the files currently (if so, display the loader)
    $scope.loader =
      cgu: false
      cgv: false

    ## various parametrable settings
    $scope.twitterSetting = { name: 'twitter_name', value: settingsPromise.twitter_name }
    $scope.aboutTitleSetting = { name: 'about_title', value: settingsPromise.about_title }
    $scope.aboutBodySetting = { name: 'about_body', value: settingsPromise.about_body }
    $scope.aboutContactsSetting = { name: 'about_contacts', value: settingsPromise.about_contacts }
    $scope.homeBlogpostSetting = { name: 'home_blogpost', value: settingsPromise.home_blogpost }
    $scope.machineExplicationsAlert = { name: 'machine_explications_alert', value: settingsPromise.machine_explications_alert }
    $scope.trainingExplicationsAlert = { name: 'training_explications_alert', value: settingsPromise.training_explications_alert }
    $scope.trainingInformationMessage = { name: 'training_information_message', value: settingsPromise.training_information_message}
    $scope.subscriptionExplicationsAlert = { name: 'subscription_explications_alert', value: settingsPromise.subscription_explications_alert }
    $scope.eventExplicationsAlert = {name: 'event_explications_alert', value: settingsPromise.event_explications_alert }
    $scope.windowStart = { name: 'booking_window_start', value: settingsPromise.booking_window_start }
    $scope.windowEnd = { name: 'booking_window_end', value: settingsPromise.booking_window_end }
    $scope.mainColorSetting = { name: 'main_color', value: settingsPromise.main_color }
    $scope.secondColorSetting = { name: 'secondary_color', value: settingsPromise.secondary_color }
    $scope.fablabName = { name: 'fablab_name', value: settingsPromise.fablab_name }
    $scope.nameGenre = { name: 'name_genre', value: settingsPromise.name_genre }
    $scope.cguFile = cguFile.custom_asset
    $scope.cgvFile = cgvFile.custom_asset
    $scope.customLogo = logoFile.custom_asset
    $scope.customLogoBlack = logoBlackFile.custom_asset
    $scope.customFavicon = faviconFile.custom_asset
    $scope.profileImage = profileImageFile.custom_asset

    $scope.enableMove =
      name: 'booking_move_enable'
      value: (settingsPromise.booking_move_enable == "true")

    $scope.moveDelay =
      name: 'booking_move_delay'
      value: parseInt(settingsPromise.booking_move_delay)

    $scope.enableCancel =
      name: 'booking_cancel_enable'
      value: (settingsPromise.booking_cancel_enable == "true")

    $scope.cancelDelay =
      name: 'booking_cancel_delay'
      value: parseInt(settingsPromise.booking_cancel_delay)

    $scope.enableReminder =
      name: 'reminder_enable'
      value: (settingsPromise.reminder_enable == 'true')

    $scope.reminderDelay =
      name: 'reminder_delay'
      value: parseInt(settingsPromise.reminder_delay)



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
    # Callback to save the setting value to the database
    # @param setting {{value:*, name:string}} note that the value will be stringified
    ##
    $scope.save = (setting)->
      # trim empty html
      if setting.value == "<br>" or setting.value == "<p><br></p>"
        setting.value = ""
      # convert dates to ISO format
      if setting.value instanceof Date
        setting.value = setting.value.toISOString()

      if setting.value isnt null
        value = setting.value.toString()
      else
        value = setting.value

      Setting.update { name: setting.name }, { value: value }, (data)->
        growl.success(_t('customization_of_SETTING_successfully_saved', {SETTING:_t(setting.name)}))
      , (error)->
        console.log(error)



    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when the upload is done: Any raised error will be displayed in a growl
    # message. If everything goes fine, a growl success message is shown.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.custom_asset?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            growl.error(err)
      else
        growl.success(_t('file_successfully_updated'))
        if content.custom_asset.name is 'cgu-file'
          $scope.cguFile = content.custom_asset
          $scope.methods.cgu = 'put'
          $scope.actionUrl.cgu += '/cgu-file' unless $scope.actionUrl.cgu.indexOf('/cgu-file') > 0
          $scope.loader.cgu = false
        else if content.custom_asset.name is 'cgv-file'
          $scope.cgvFile = content.custom_asset
          $scope.methods.cgv = 'put'
          $scope.actionUrl.cgv += '/cgv-file' unless $scope.actionUrl.cgv.indexOf('/cgv-file') > 0
          $scope.loader.cgv = false
        else if content.custom_asset.name is 'logo-file'
          $scope.customLogo = content.custom_asset
          $scope.methods.logo = 'put'
          $scope.actionUrl.logo += '/logo-file' unless $scope.actionUrl.logo.indexOf('/logo-file') > 0
        else if content.custom_asset.name is 'logo-black-file'
          $scope.customLogoBlack = content.custom_asset
          $scope.methods.logoBlack = 'put'
          $scope.actionUrl.logoBlack += '/logo-black-file' unless $scope.actionUrl.logoBlack.indexOf('/logo-black-file') > 0
        else if content.custom_asset.name is 'favicon-file'
          $scope.customFavicon = content.custom_asset
          $scope.methods.favicon = 'put'
          $scope.actionUrl.favicon += '/favicon-file' unless $scope.actionUrl.favicon.indexOf('/favicon-file') > 0
        else if content.custom_asset.name is 'profile-image-file'
          $scope.profileImage = content.custom_asset
          $scope.methods.profileImage = 'put'
          $scope.actionUrl.profileImage += '/profile-image-file' unless $scope.actionUrl.profileImage.indexOf('/profile-image-file') > 0



    ##
    # @param target {String} 'cgu' | 'cgv'
    ##
    $scope.addLoader = (target) ->
      $scope.loader[target] = true



    ### PRIVATE SCOPE ###

    ##
    # Kind of constructor: these actions will be realized first when the controller is loaded
    ##
    initialize = ->
      # set the authenticity tokens in the forms
      CSRF.setMetaTags()

      # we prevent the admin from setting the closing time before the opening time
      $scope.$watch 'windowEnd.value', (newValue, oldValue, scope) ->
        if $scope.windowStart and moment($scope.windowStart.value).isAfter(newValue)
          $scope.windowEnd.value = oldValue

      # change form methods to PUT if items already exists
      if cguFile.custom_asset
        $scope.methods.cgu = 'put'
        $scope.actionUrl.cgu += '/cgu-file'
      if cgvFile.custom_asset
        $scope.methods.cgv = 'put'
        $scope.actionUrl.cgv += '/cgv-file'
      if logoFile.custom_asset
        $scope.methods.logo = 'put'
        $scope.actionUrl.logo += '/logo-file'
      if logoBlackFile.custom_asset
        $scope.methods.logoBlack = 'put'
        $scope.actionUrl.logoBlack += '/logo-black-file'
      if faviconFile.custom_asset
        $scope.methods.favicon = 'put'
        $scope.actionUrl.favicon += '/favicon-file'
      if profileImageFile.custom_asset
        $scope.methods.profileImage = 'put'
        $scope.actionUrl.profileImage += '/profile-image-file'


    # init the controller (call at the end !)
    initialize()

]
