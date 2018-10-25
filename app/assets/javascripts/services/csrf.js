/* eslint-disable
    no-undef,
    no-useless-escape,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
'use strict'

Application.Services.service('CSRF', ['$cookies',
  $cookies =>
    ({
      setMetaTags () {
        if (angular.element('meta[name="csrf-param"]').length === 0) {
          angular.element('head').append('<meta name="csrf-param" content="authenticity_token">')
          angular.element('head').append(`<meta name=\"csrf-token\" content=\"${$cookies['XSRF-TOKEN']}\">`)
        } else {
          angular.element('meta[name="csrf-token"]').replaceWith(`<meta name=\"csrf-token\" content=\"${$cookies['XSRF-TOKEN']}\">`)
        }
      }
    })

])
