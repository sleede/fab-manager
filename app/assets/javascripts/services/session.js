/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict'

Application.Services.service('Session', [ function () {
  this.create = function (user) {
    return this.currentUser = user
  }

  this.destroy = function () {
    return this.currentUser = null
  }

  return this
}
])
