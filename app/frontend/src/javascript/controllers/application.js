
Application.Controllers.controller('ApplicationController', ['$rootScope', '$scope', '$transitions', '$window', '$locale', '$timeout', 'Session', 'AuthService', 'Auth', '$uibModal', '$state', 'growl', 'Notification', '$interval', 'Setting', '_t', 'Version', 'Help', '$cookies',
  function ($rootScope, $scope, $transitions, $window, $locale, $timeout, Session, AuthService, Auth, $uibModal, $state, growl, Notification, $interval, Setting, _t, Version, Help, $cookies) {
  /* PRIVATE STATIC CONSTANTS */

    // User's notifications will get refreshed every 30s
    const NOTIFICATIONS_CHECK_PERIOD = 30000;

    /* PUBLIC SCOPE */

    // Fab-manager's version
    $scope.version =
      { current: '' };

    // currency symbol for the current locale (cf. angular-i18n)
    $rootScope.currencySymbol = $locale.NUMBER_FORMATS.CURRENCY_SYM;

    /**
     * Set the current user to the provided value and initialize the session
     * @param user {Object} Rails/Devise user
     */
    $scope.setCurrentUser = function (user) {
      if (!angular.isUndefinedOrNull(user)) {
        $rootScope.currentUser = user;
        Session.create(user);
        getNotifications();
        // Fab-manager's app-version
        if (user.role === 'admin') {
          // get the version
          $scope.version = Version.get({ origin: window.location.origin });
        } else {
          $scope.version = { current: '' };
        }
      }
    };

    /**
     * Login callback
     * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
     * @param callback {function}
     */
    $scope.login = function (e, callback) {
      if (e) { e.preventDefault(); }
      return openLoginModal(null, null, callback);
    };

    /**
     * Logout callback
     * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.logout = function (e) {
      e.preventDefault();
      return Auth.logout().then(function () {
        Session.destroy();
        $rootScope.currentUser = null;
        $rootScope.toCheckNotifications = false;
        $scope.notifications = {
          total: 0,
          unread: 0
        };
        $cookies.remove('fablab_cart_token');
        return $state.go('app.public.home');
      }, function (error) {
        console.error(`An error occurred logging out: ${error}`);
      });
    };

    /**
     * Open the modal window allowing the user to create an account.
     * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.signup = function (e) {
      if (e) { e.preventDefault(); }
      if (Fablab.activeProviderType !== 'DatabaseProvider') {
        $window.location.href = '/sso-redirect';
      } else {
        return $uibModal.open({
          templateUrl: '/shared/signupModal.html',
          backdrop: 'static',
          keyboard: false,
          size: 'md',
          resolve: {
            settingsPromise: ['Setting', function (Setting) {
              return Setting.query({ names: "['phone_required', 'recaptcha_site_key', 'confirmation_required', 'address_required']" }).$promise;
            }],
            profileCustomFieldsPromise: ['ProfileCustomField', function (ProfileCustomField) { return ProfileCustomField.query({}).$promise; }],
            proofOfIdentityTypesPromise: ['SupportingDocumentType', function (SupportingDocumentType) { return SupportingDocumentType.query({}).$promise; }]
          },
          controller: ['$scope', '$uibModalInstance', 'Group', 'CustomAsset', 'settingsPromise', 'growl', '_t', 'profileCustomFieldsPromise', 'proofOfIdentityTypesPromise', function ($scope, $uibModalInstance, Group, CustomAsset, settingsPromise, growl, _t, profileCustomFieldsPromise, proofOfIdentityTypesPromise) {
            // default parameters for the date picker in the account creation modal
            $scope.datePicker = {
              format: Fablab.uibDateFormat,
              opened: false,
              options: {
                startingDay: Fablab.weekStartingDay,
                maxDate: new Date()
              }
            };

            // is the phone number required to sign-up?
            $scope.phoneRequired = (settingsPromise.phone_required === 'true');

            // is the address required to sign-up?
            $scope.addressRequired = (settingsPromise.address_required === 'true');

            // reCaptcha v2 site key (or undefined)
            $scope.recaptchaSiteKey = settingsPromise.recaptcha_site_key;

            // callback to open the date picker (account creation modal)
            $scope.openDatePicker = function ($event) {
              $event.preventDefault();
              $event.stopPropagation();
              $scope.datePicker.opened = true;
            };

            $scope.profileCustomFields = profileCustomFieldsPromise.filter(f => f.actived);

            // retrieve the groups (standard, student ...)
            Group.query(function (groups) {
              $scope.groups = groups;
              $scope.enabledGroups = groups.filter(g => !g.disabled);
            });

            // retrieve the CGU
            CustomAsset.get({ name: 'cgu-file' }, function (cgu) {
              $scope.cgu = cgu.custom_asset;
            });

            // default user's parameters
            $scope.user = {
              is_allow_contact: false,
              is_allow_newsletter: false,
              // reCaptcha response, received from Google (through AJAX) and sent to server for validation
              recaptcha: undefined,
              invoicing_profile_attributes: {
                user_profile_custom_fields_attributes: $scope.profileCustomFields.map(f => {
                  return { profile_custom_field_id: f.id };
                })
              }
            };

            $scope.hasProofOfIdentityTypes = function (groupId) {
              return proofOfIdentityTypesPromise.filter(t => t.group_ids.includes(groupId)).length > 0;
            };

            $scope.groupName = function (groupId) {
              if (!$scope.enabledGroups || groupId === undefined || groupId === null) {
                return '';
              }
              return $scope.enabledGroups.find(g => g.id === groupId).name;
            };

            // Errors display
            $scope.alerts = [];
            $scope.closeAlert = function (index) {
              $scope.alerts.splice(index, 1);
            };

            // callback for form validation
            $scope.ok = function () {
              // try to create the account
              $scope.alerts = [];
              // remove 'organization' attribute
              const orga = $scope.user.organization;
              delete $scope.user.organization;
              // register on server
              return Auth.register($scope.user).then(function (user) {
                if (user.id) {
                  // creation successful
                  $uibModalInstance.close({
                    user,
                    settings: settingsPromise
                  });
                } else {
                  // the user was not saved in database, something wrong occurred
                  growl.error(_t('app.public.common.unexpected_error_occurred'));
                }
              }, function (error) {
                // creation failed...
                // restore organization param
                $scope.user.organization = orga;
                // display errors
                angular.forEach(error.data.errors, function (v, k) {
                  angular.forEach(v, function (err) {
                    $scope.alerts.push({
                      msg: k + ': ' + err,
                      type: 'danger'
                    });
                  });
                });
              });
            };

            $scope.dismiss = function () {
              $uibModalInstance.dismiss('cancel');
            };
          }]
        }).result.finally(null).then(function (res) {
          // when the account was created successfully, set the session to the newly created account
          if (res.settings.confirmation_required === 'true') {
            Auth._currentUser = null;
            growl.info(_t('app.public.common.you_will_receive_confirmation_instructions_by_email_detailed'));
          } else {
            $scope.setCurrentUser(res.user);
          }
        });
      }
    };

    /**
     * Open the modal window allowing the user to change his password.
     * @param token {string} security token for password changing. The user should have recieved it by mail
     */
    $scope.editPassword = function (token) {
      $uibModal.open({
        templateUrl: '/shared/passwordEditModal.html',
        size: 'md',
        controller: ['$scope', '$uibModalInstance', '$http', function ($scope, $uibModalInstance, $http) {
          $scope.user = { reset_password_token: token };
          $scope.alerts = [];
          $scope.closeAlert = function (index) {
            $scope.alerts.splice(index, 1);
          };

          $scope.changePassword = function () {
            $scope.alerts = [];
            return $http.put('/users/password.json', { user: $scope.user }).then(function () { $uibModalInstance.close(); }).catch(function (data) {
              angular.forEach(data.data.errors, function (v, k) {
                angular.forEach(v, function (err) {
                  $scope.alerts.push({
                    msg: k + ': ' + err,
                    type: 'danger'
                  });
                });
              });
            });
          };
        }]
      }).result.finally(null).then(function () {
        growl.success(_t('app.public.common.your_password_was_successfully_changed'));
        return Auth.login().then(function (user) {
          $scope.setCurrentUser(user);
        }, function (error) {
          console.error(`Authentication failed: ${JSON.stringify(error)}`);
        }
        );
      });
    };

    /**
     * Compact/Expend the width of the left navigation bar
     * @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.toggleNavSize = function (event) {
      let $classes, $targets;
      if (typeof event === 'undefined') {
        console.error('[ApplicationController::toggleNavSize] Missing event parameter');
        return;
      }

      let toggler = $(event.target);
      if (!toggler.data('toggle')) { toggler = toggler.closest('[data-toggle^="class"]'); }

      const $class = toggler.data().toggle;
      const $target = toggler.data('target') || toggler.attr('data-link');

      if ($class) {
        const $tmp = $class.split(':')[1];
        if ($tmp) { $classes = $tmp.split(','); }
      }

      if ($target) {
        $targets = $target.split(',');
      }

      if ($classes && $classes.length) {
        $.each($targets, function (index) {
          if ($classes[index].indexOf('*') !== -1) {
            const patt = new RegExp('\\s',
              +$classes[index].replace(/\*/g, '[A-Za-z0-9-_]+').split(' ').join('\\s|\\s'),
              +'\\s', 'g');
            $(toggler).each(function (i, it) {
              let cn = ` ${it.className} `;
              while (patt.test(cn)) {
                cn = cn.replace(patt, ' ');
              }
              it.className = $.trim(cn);
            });
          }

          return (($targets[index] !== '#') && $($targets[index]).toggleClass($classes[index])) || toggler.toggleClass($classes[index]);
        });
      }

      toggler.toggleClass('active');
    };

    /**
     * Open the modal dialog showing that an upgrade is available
     */
    $scope.versionModal = function () {
      if ($scope.version.up_to_date) return;
      if ($rootScope.currentUser.role !== 'admin') return;

      $uibModal.open({
        templateUrl: '/admin/versions/upgradeModal.html',
        controller: 'VersionModalController',
        resolve: {
          version () { return $scope.version; }
        }
      });
    };

    /**
     * Trigger the contextual help "feature tour".
     * @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.help = function (event) {
      event.preventDefault();

      // we wrap the event triggering into a $timeout to prevent conflicting with current $apply
      $timeout(function () {
        const evt = new KeyboardEvent('keydown', { key: 'F1' });
        window.dispatchEvent(evt);
      });
    };

    /* PRIVATE SCOPE */
    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // try to retrieve any currently logged user
      Auth.login().then(function (user) {
        $scope.setCurrentUser(user);
        // force users to complete their profile if they are not
        if (user.need_completion) {
          return $state.transitionTo('app.logged.profileCompletion');
        }
      }, function () {
        console.info('No users currently logged');
        $rootScope.toCheckNotifications = false;
      });

      // bind to the $transitions.onStart event (UI-Router)
      $transitions.onStart({}, function (trans) {
        if (!trans.$to().data) { return; }

        const { authorizedRoles } = trans.$to().data;
        if (!AuthService.isAuthorized(authorizedRoles)) {
          if (AuthService.isAuthenticated()) {
          // user is not allowed
            console.error('[ApplicationController::initialize] user is not allowed');
            return false;
          } else {
          // user is not logged in
            openLoginModal(trans.$to().name, trans.$to().params);
            return false;
          }
        }
      });

      // we stop polling notifications when the page is not in foreground
      onPageVisible(function (state) { $rootScope.toCheckNotifications = (state === 'visible'); });

      Setting.query({ names: "['fablab_name', 'name_genre', 'link_name']" }, function (settings) {
        $scope.fablabName = settings.fablab_name;
        $scope.nameGenre = settings.name_genre;
        $scope.linkName = settings.link_name;
      });

      // shorthands
      $scope.isAuthenticated = Auth.isAuthenticated;
      $scope.isAuthorized = AuthService.isAuthorized;
      $rootScope.login = $scope.login;

      // handle F1 key to trigger help
      window.addEventListener('keydown', Help);
    };

    /**
     * Retrieve once the notifications from the server and display a message popup for each new one.
     * Then, periodically check for new notifications.
     */
    const getNotifications = function () {
      $rootScope.toCheckNotifications = true;
      if (!$rootScope.checkNotificationsIsInit && !!$rootScope.currentUser) {
        setTimeout(function () {
          // we request the most recent notifications
          Notification.last_unread(function (notifications) {
            $rootScope.lastCheck = new Date();
            $scope.notifications = notifications.totals;

            const toDisplay = [];
            angular.forEach(notifications.notifications, function (n) { toDisplay.push(n); });

            if (toDisplay.length < notifications.totals.unread) {
              toDisplay.push({ message: { description: _t('app.public.common.and_NUMBER_other_notifications', { NUMBER: notifications.totals.unread - toDisplay.length }) } });
            }

            angular.forEach(toDisplay, function (notification) { growl.info(notification.message.description); });
          });
        }, 2000);

        const checkNotifications = function () {
          if ($rootScope.toCheckNotifications) {
            return Notification.polling({ last_poll: $rootScope.lastCheck }).$promise.then(function (data) {
              $rootScope.lastCheck = new Date();
              $scope.notifications = data.totals;

              angular.forEach(data.notifications, function (notification) { growl.info(notification.message.description); });
            }).catch(function (error) {
              console.error('Error while polling notifications', error);
            });
          }
        };

        $interval(checkNotifications, NOTIFICATIONS_CHECK_PERIOD);
        $rootScope.checkNotificationsIsInit = true;
      }
    };

    /**
     * Open the modal window allowing the user to log in.
     */
    const openLoginModal = function (toState, toParams, callback) {
      if (Fablab.activeProviderType !== 'DatabaseProvider') {
        $window.location.href = '/sso-redirect';
      } else {
        return $uibModal.open({
          templateUrl: '/shared/deviseModal.html',
          backdrop: 'static',
          size: 'sm',
          resolve: {
            settingsPromise: ['Setting', function (Setting) {
              return Setting.query({ names: "['confirmation_required', 'public_registrations']" }).$promise;
            }]
          },
          controller: ['$scope', '$uibModalInstance', '_t', 'settingsPromise', function ($scope, $uibModalInstance, _t, settingsPromise) {
            const user = ($scope.user = {});

            // email confirmation required before user sign-in?
            $scope.confirmationRequired = settingsPromise.confirmation_required;

            // is public registrations allowed?
            $scope.publicRegistrations = (settingsPromise.public_registrations !== 'false');

            $scope.login = function () {
              Auth.login(user).then(function (user) {
                // Authentication succeeded ...
                $uibModalInstance.close(user);
                if (callback && (typeof callback === 'function')) {
                  return callback(user);
                }
              }
              , function (error) {
                console.error(`Authentication failed: ${JSON.stringify(error)}`);
                $scope.alerts = [];
                return $scope.alerts.push({
                  msg: error.data.error,
                  type: 'danger'
                });
              });
            };
            // handle modal behaviors. The provided reason will be used to define the following actions
            $scope.dismiss = function () {
              $uibModalInstance.dismiss('cancel');
            };

            $scope.openSignup = function (e) {
              e.preventDefault();
              return $uibModalInstance.dismiss('signup');
            };

            $scope.openConfirmationNewModal = function (e) {
              e.preventDefault();
              return $uibModalInstance.dismiss('confirmationNew');
            };

            $scope.openResetPassword = function (e) {
              e.preventDefault();
              return $uibModalInstance.dismiss('resetPassword');
            };
          }]
        }).result.finally(null).then(function (user) {
          // what to do when the modal is closed

          // authentication succeeded, set the session, gather the notifications and redirect
          GTM.trackLogin();
          $scope.setCurrentUser(user);

          if ((toState !== null) && (toParams !== null)) {
            return $state.go(toState, toParams);
          }
        }, function (reason) {
          // authentication did not end successfully
          if (reason === 'signup') {
            // open sign-up modal
            $scope.signup();
          } else if (reason === 'resetPassword') {
            // open the 'reset password' modal
            return $uibModal.open({
              templateUrl: '/shared/passwordNewModal.html',
              size: 'sm',
              controller: ['$scope', '$uibModalInstance', '$http', function ($scope, $uibModalInstance, $http) {
                $scope.user = { email: '' };
                $scope.sendReset = function () {
                  return $http.post('/users/password.json', { user: $scope.user }).then(function () {
                    $uibModalInstance.close();
                  });
                };
              }]
            }).result.finally(null).then(function () {
              growl.info(_t('app.public.common.you_will_receive_in_a_moment_an_email_with_instructions_to_reset_your_password'));
            });
          } else if (reason === 'confirmationNew') {
            // open the 'reset password' modal
            return $uibModal.open({
              templateUrl: '/shared/ConfirmationNewModal.html',
              size: 'sm',
              controller: ['$scope', '$uibModalInstance', '$http', function ($scope, $uibModalInstance, $http) {
                $scope.user = { email: '' };
                $scope.submitConfirmationNewForm = function () {
                  return $http.post('/users/confirmation.json', { user: $scope.user }).then(function () {
                    $uibModalInstance.close();
                  });
                };
              }]
            }).result.finally(null).then(function () {
              growl.info(_t('app.public.common.you_will_receive_confirmation_instructions_by_email_detailed'));
            });
          }
        });
        // otherwise the user just closed the modal
      }
    };

    /**
     * Detect if the current page (tab/window) is active of put as background.
     * When the status changes, the callback is triggered with the new status as parameter
     * Inspired by http://stackoverflow.com/questions/1060008/is-there-a-way-to-detect-if-a-browser-window-is-not-currently-active#answer-1060034
     */
    const onPageVisible = function (callback) {
      let hidden = 'hidden';

      const onchange = function (evt) {
        const v = 'visible';
        const h = 'hidden';
        const evtMap = {
          focus: v,
          focusin: v,
          pageshow: v,
          blur: h,
          focusout: h,
          pagehide: h
        };
        evt = evt || window.event;
        if (evt.type in evtMap) {
          if (typeof callback === 'function') { callback(evtMap[evt.type]); }
        } else {
          const visibility = this[hidden] ? 'hidden' : 'visible';
          if (typeof callback === 'function') { callback(visibility); }
        }
      };

      // Standards:
      if (hidden in document) {
        document.addEventListener('visibilitychange', onchange);
      } else if ((hidden = 'mozHidden') in document) {
        document.addEventListener('mozvisibilitychange', onchange);
      } else if ((hidden = 'webkitHidden') in document) {
        document.addEventListener('webkitvisibilitychange', onchange);
      } else if ((hidden = 'msHidden') in document) {
        document.addEventListener('msvisibilitychange', onchange);
        // IE 9 and lower
      } else if ('onfocusin' in document) {
        document.onfocusin = (document.onfocusout = onchange);
        // All others
      } else {
        window.onpageshow = (window.onpagehide = (window.onfocus = (window.onblur = onchange)));
      }
      // set the initial state (but only if browser supports the Page Visibility API)
      if (document[hidden] !== undefined) {
        return onchange({ type: document[hidden] ? 'blur' : 'focus' });
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the modal showing details about the version and the upgrades
 */
Application.Controllers.controller('VersionModalController', ['$scope', '$uibModalInstance', 'version', function ($scope, $uibModalInstance, version) {
  // version infos (current version + upgrade infos from hub)
  $scope.version = version;

  // callback to close the modal
  $scope.close = function () {
    $uibModalInstance.dismiss();
  };
}]);
