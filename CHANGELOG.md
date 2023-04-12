# Changelog Fab-manager

## v6.0.3 2023 April 12

- Fix a bug: unable to install Fab-manager by setup.sh
- Update translations from Crowdin
- Fix a security issue: updated Ruby to 3.2.2 to fix [CVE-2023-28755](https://www.ruby-lang.org/en/news/2023/03/28/redos-in-uri-cve-2023-28755/)
- Fix a security issue: updated Ruby to 3.2.2 to fix [CVE-2023-28756](https://www.ruby-lang.org/en/news/2023/03/30/redos-in-time-cve-2023-28756/)

## v6.0.2 2023 April 05

- Italian language support (credits to https://crowdin.com/profile/olazzari)
- Improved error message on payzen misconfigured currency
- Improved reporting error messages in UI, from ruby exceptions
- Fix a bug: unable to subscribe with a payment schedule using PayZen
- Fix a bug: unable to list supporting documents types for a deleted group
- Fix a bug: notification is broken when updating payzen currency
- Fix a bug: broken notifications
- Fix a bug: unable to bulk update settings

## v6.0.1 2023 April 03

- Fix a bug: unable to write the configuration of the auth provider

## v6.0.0 2023 April 03

- Updated ruby to 3.2
- Updated rails to 7.0
- Updated puma to 6.1
- Updated responders to 3.0
- Updated devise to 4.9
- Updated sassc to 2.4
- Updated sentry to 5.8
- Updated web-console to 4.2
- Updated shakapacker to 6.6
- Updated bootsnap to 1.16
- Updated pg to 1.4
- Updated nodejs to 18.15
- Updated oj to 3.14
- Updated multi_json to 1.15
- Updated spring to 4.0
- Updated spring-watcher-listen to 2.1
- Updated omniauth to 2.1
- Updated omniauth-rails_csrf_protection to 1.0
- Updated omniauth_openid_connect to 0.6
- Updated the invoices chaining method with a more flexible model
- Fill the holes in the logical sequence of invoices references with nil invoices
- Use a cached configuration file to read the authentication provider settings
- Order numbers are now saved in database instead of generated on-the-fly
- OpenAPI availabilities endpoint
- Ability to filter OpenAPI reservations endpoint by availability_id
- Support for ARM64 CPU architecture
- Fix a bug: by default, invoices should be ordered by date descending
- Fix a bug: broken display after a plan category was deleted
- Fix a bug: unable to update recurring event
- Fix a security issue: updated json5 to 2.2.2 to fix [CVE-2022-46175](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-46175)
- Fix a security issue: updated terser to 5.16.8 to fix [CVE-2022-25858](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-25858)
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/mount-auth-provider.sh | bash`
- [TODO DEPLOY] `rails fablab:auth:write_provider`
- [TODO DEPLOY] `rails fablab:restore_order_number` THEN `rails fablab:fix_references`

## v5.9.1 2023 March 22

- Fix a bug: logical sequence of invoices references has duplicates
- Fix a bug: in some cases, unable to export to excel files
- Fix a security issue: updated rack to 2.2.6.4 to fix [CVE-2023-27539](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-27539)

## v5.9.0 2023 March 20

- Ability to restrict machine reservations per plan
- Ability to restrict machine availabilities per plan
- Ability to configure a prior period for each reservation type to prevent booking (#440)
- Admins cannot select the date when creating a refund invoice anymore
- Fix a bug: JS date is initalialized 1 day before in negative timezones (#445)
- Fix a bug: user's profile field gender is now marked as required
- Fix a bug: logical sequence of invoices references is broken, when using the store module or the payments schedules
- Fix a bug: refund invoices may generate duplicates in invoices references
- Fix a security issue: updated webpack to 5.76.0 to fix [CVE-2023-28154](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-28154)
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v5.8.2 2023 March 13

- Improved upgrade script
- Keep usage history of prepaid packs
- OpenAPI reservation endpoint can be filtered by date
- OpenAPI users endpoint now returns the ID of the InvoicingProfile
- Fix a bug: URL validation regex was wrong
- Fix a bug: privileged users cannot order free carts for themselves in the store
- Fix a bug: unable to select a new machine for an existing category
- Fix a bug: wrong counting of minutes used when using a prepaid pack
- Fix a bug: empty advanced accounting code is not defaulted to the general setting
- Fix a bug: invalid style in accounting codes settings
- Fix a bug: wrong namespace for task cart_operator
- Fix a security issue: updated rack to 2.2.6.3 to fix [CVE-2023-27530](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-27530)
- [TODO DEPLOY] `rails fablab:fix:cart_operator`
- [TODO DEPLOY] `rails fablab:setup:build_accounting_lines`
- [TODO DEPLOY] `rails fablab:fix:pack_minutes_used`

## v5.8.1 2023 March 03

- Fix a bug: unable to reserve an event

## v5.8.0 2023 March 03

- OpenAPI events endpoint returns category, theme and age_range
- OpenAPI reservation endpoint will return details for the reserved slots
- Display info messages if the user cannot buy prepaid packs
- Fix a bug: some OpenAPI endpoints struggle and expire with timeout
- Fix a bug: OpenAPI events endpoint documentation does not refect the returned data
- Fix a bug: members can't change/cancel their reservations
- Fix a bug: admin events view should default to the list tab
- Fix a bug: event creation form should not allow setting multiple times the same price category
- Fix a bug: MAX_SIZE env varibles should not be quoted (#438)
- Fix a bug: unable to add OIDC scopes without discovery
- [BREAKING CHANGE] GET `open_api/v1/events` will necessarily be paginated
- [BREAKING CHANGE] GET `open_api/v1/invoices` will necessarily be paginated
- [BREAKING CHANGE] GET `open_api/v1/reservations` will necessarily be paginated
- [BREAKING CHANGE] GET `open_api/v1/users` will necessarily be paginated
- [BREAKING CHANGE] GET `open_api/v1/subscriptions` won't return `total_count`, `total_pages`, `page` or `page_siez` anymore. RFC-5988 headers (*Link*, *Total* and *Per-Page*) will continue to provide these same data.
- [BREAKING CHANGE] GET `open_api/v1/subscriptions` will return a `subscriptions` array instead of a `data` array.

## v5.7.2 2023 February 24

- Fix a bug: unable to update recurrent events
- Fix a bug: invalid border color for slots
- Fix a bug: members can't change/cancel their reservations

## v5.7.1 2023 February 20

- Fix a bug: timezone is ignored while configuring calendar opening/closing time
- Fix a bug: unable to configure RAILS_LOCALE to fr-CA
- Fix a bug: unable to fix availabilities for events
- Fix a bug: unable to start Fab-manager with message: maximum must be a nonnegative Integer
- Fix a bug: unable to export orders statistics
- Fix a bug: invalid shell coloring during setup
- [TODO DEPLOY] `fablab:maintenance:clean_availabilities`

## v5.7.0 2023 February 17

- Report user's prepaid packs in the dashboard
- Export external ID and private notes in the members excel export
- Ability to buy a new prepaid pack from the user's dashboard
- Improved calendars loading time
- Admin notification when an order was placed
- Management of notifications preferences for admins
- Display custom banners in machines/trainings/events lists
- Filter projects by status
- Maximum validity period for trainings authorizations
- Automatically cancel trainings with insufficient attendees
- Check SCSS syntax before saving home page style
- Use Time instead of DateTime objects
- Fix a bug: missing statististics subtypes
- Fix a bug: wrong times in admin/event monitoring
- Fix a bug: daylight saving time is ignored and result in wrong dates and/or times when dealing around the DST day
- Fix a bug: date shift in event creation/update
- Fix a bug: unable to run `rails db:seed` when first setup Fab-manager
- Fix a bug: cannot cancel a subscription after offering free days
- Fix a bug: event image updates are not reflected unless the browser's cache is purged
- Fix a bug: schedules jobs are not launched at the right time
- Fix a bug: unable to update the title of a training
- Fix a bug: members cannot update their cards for payment schedules
- [TODO DEPLOY] `rails fablab:fix_availabilities` THEN `rails fablab:setup:build_places_cache`
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/rename-supporting-document.sh | bash`
- [TODO DEPLOY] `rails db:seed`

## v5.6.11 2023 February 07

- OpenAPI endpoint to fetch subscription data
- Fix a bug: invalid date display in negative timezones
- Fix a bug: unable to get the latest payment_gateway_object for plan/machine/training/space

## v5.6.10 2023 February 02

- Optimized memory consumption in statistics fetcher service
- Fix a bug: private method `create_statistic_subtype'
- [TODO DEPLOY] `rails db:seed`

## v5.6.9 2023 February 02

- Updated shakapaker to 6.5.5
- Fix a bug: unable to filter statistics by slot date
- Fix a bug: unable to create a recurrent event
- Fix a bug: unable to create a non-rolling plan
- Fix a bug: invalid duration for machine/spaces reservations in statistics, when using slots of not 1 hour
- Fix a bug: invalid month in date format
- Fix a bug: do not show theme and age-range fields in event form if no options were set
- Fix a bug: do not show catgory select in plan form if no options were set
- Fix a bug: new setups doesn't log
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `rails fablab:es:build_stats` THEN `rails fablab:maintenance:regenerate_statistics[2014,1]`

## v5.6.8 2023 January 26

- Fix a bug: plan prices are not reported correctly in the interface

## v5.6.7 2023 January 25

- Fix a bug: updating plan prices
- Fix a bug: admin cannot book an event for himself

## v5.6.6 2023 January 23

- Add more context data to sentry reports
- Improved SSO testing
- Ability to map the external ID from the SSO
- Ability to soft-destroy a reserved event
- Fix a bug: unable to run task fix_invoice_item when some invoice items are associated with errors
- Fix a bug: invalid event date reported when the timezone in before UTC
- Fix a bug: unable to run accounting export if a line label was not defined
- Fix a security issue: updated rack to 2.2.6.2 to fix [CVE-2022-44571](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-44571)
- Fix a security issue: updated globalid to 1.0.1 to fix [CVE-2023-22799](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-22799)
- [TODO DEPLOY] `rails fablab:fix:invoice_items_in_error` THEN `rails fablab:fix_invoice_items` THEN `rails db:migrate`

## v5.6.5 2023 January 9

- Moved the buttons to create a new machine or availability to the admin section
- Fix a bug: unable to create/update machines/spaces/trainings/events/...

## v5.6.4 2023 January 9

- Fix a bug: unable to build the docker image (yarn error extracting tar content of undefined failed)

## v5.6.3 2023 January 9

- Fix a bug: unable to build the docker image (yarn error extracting tar content of undefined failed)
- Fix a security issue: logged users but non-admins can access to analytics data throught the API

## v5.6.2 2023 January 9

- Improved fix_invoice_item task
- Improved test coverage
- Fix a bug: unable to set some dates for the events if user is in negative timezone
- Fix a bug: events are shown as over and unbookable, starting from midnight at the event end's day
- Fix a bug: updating a space/machine/event/training removes the image
- Fix a bug: cryptic error message when failed to create a manager
- Fix a bug: unable to restore accounting periods closed by a deleted admin
- Fix a bug: unable to build an accounting archive if the operator was deleted
- Fix a bug: unable to update an event category

## v5.6.1 2023 January 6

- Fix a bug: allow decimal values for VAT rates
- Fix a bug: canceled reservations/slots not shown as it in the reservations dashboard
- Fix a bug: no main item on some invoices
- Fix a bug: unable to build accounting lines if no invoices
- Fix a bug: unable to apply rounding correction on accounting lines
- Fix a bug: empty object for some invoice item
- Fix a bug: unable to filter Show only slots with reservations in public calendar for admin
- Fix a security issue: updated json5 to 1.0.2 to fix [CVE-2022-46175](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-46175)
- [TODO DEPLOY] `rails fablab:fix_invoice_items` => run this script BEFORE running the migrations

## v5.6.0 2023 January 5

- Ability to group machines by categories
- Ability to mark a machine as reservable or not
- Ability to filter the admin's calendar
- Private note on member's profile
- Optional external identifier for users
- Ability to disable generation of invoices at zero
- Accounting data is now built each night and saved in database
- Ability to define multiple accounting journal codes
- Ability to define accounting codes per resources (aka. advanced accounting)
- Ability to change the name of the VAT
- Ability to cancel a running subscription from the member edition view for admin/managers
- OpenAPI endpoint to fetch accounting data
- Add reservation deadline parameter (#414)
- Verify current password at server side when changing password
- Password strengh indicator
- Updated OpenAPI documentation
- Updated OpenID Connect documentation
- OpenAPI users endpoint offer ability to filter by created_after
- OpenAPI users endpoint return first name, last name, gender, organization and address
- Default accounting codes and labels if not set
- Active serving static files from the `/public` folder by default from rails
- Display custom error message if the PDF invoice is not found
- Report subsription mismatch with user's group
- Added sentry for error reporting
- Report details of the due for invoices related to a payment schedule
- Migrated plan/machine/space/event forms to react
- Fix a bug: unable to run test in negative timezones (#425)
- Fix a bug: providing an array of attributes to filter OpenApi data, results in error
- Fix a bug: unable to manage stocks on new products
- Fix a bug: unsupported param[] syntax in OpenAPI
- Fix a bug: unable to access in-system notifications if a slot was cancelled
- Fix a bug: feature tour in admin/settings is broken
- Fix a bug: clearing the new expiration date field in the offer days modal result in errors
- Fix a bug: low stock notification is always sent if one of the stocks has reached the threshold
- Fix a bug: unable to update title of availability after admin remove a machine/plan in calendar
- Fix a bug: unable to access files from the public folder (like example.csv)
- Fix a bug: unable to return to the statistics tab
- Fix a bug: payment schedule by check result in error if payment mean was not changed
- Fix a security issue: updated httparty to 0.21.0 to fix [GHSA-5pq7-52mg-hr42](https://github.com/advisories/GHSA-5pq7-52mg-hr42)
- Updated react-modal to 3.16.1
- Updated tiptap editor and its dependencies to 2.0.0-beta.204
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `rails fablab:setup:build_accounting_lines`
- [TODO DEPLOY] `rails fablab:fix:cart_operator`

## v5.5.8 2022 December 16

- Fix a bug: wrong reservations count for spaces in availabilities export (#415)
- Fix a bug: phone or address required are not marked as it, in create manager/admin form
- Fix a security issue: updated express to 4.18.2 to fix [CVE-2022-24999](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24999)
- Fix a security issue: updated @claviska/jquery-minicolors to 2.3.6 to fix [CVE-2021-4243](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-4243)
- Fix a security issue: updated loofah to 2.19.1 to fix [CVE-2022-23514](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23514), [CVE-2022-23515](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23515) and [CVE-2022-23516](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23516)
- Fix a security issue: updated rails-html-sanitizer to 1.4.4 to fix [CVE-2022-23517](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23517), [CVE-2022-23518](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23518), [CVE-2022-23519](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23519), [CVE-2022-23520](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23520) and [CVE-2022-32209](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-32209)
- Removed gem rails_12factor
- [TODO DEPLOY] add the `RAILS_LOG_TO_STDOUT=true` environment variable (see [doc/environment.md](doc/environment.md#RAILS_LOG_TO_STDOUT) for configuration details)

## v5.5.7 2022 December 13

- Fix a bug: unable to update/delete a space
- Fix a bug: unable to credit wallet
- Fix a security issue: updated nokogiri to 1.13.10 to fix [CVE-2022-23476](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23476)

## v5.5.6 2022 December 05

- Updated FabAnalytics reports to include new features
- Fix a bug: setting somes decimal amounts (e.g. 4,85) result in another amount (e.g. 4,84)
- Fix a bug: unable to export statistics
- Fix a bug: soft destroyed machines and spaces are still reported in the OpenAPI

## v5.5.5 2022 November 22

- Soft destroy of spaces and machines
- Fix a bug: in upgrade script, the error "the input device is not a TTY" is thrown when migrating the database
- Fix a bug: broken display of machines pages
- Fix a bug: some automated tests were randomly failing because ElasticSearch was not synced
- Fix a bug: payment related objects are not synced on Stripe when enabling the online payment module
- Fix a bug: unable set a main image of product and remove an image of product

## v5.5.4 2022 November 17

- Fix a bug: unable to download an existing export of the statistics
- Fix a security issue: updated loader-utils to 2.0.4 to fix [CVE-2022-37601](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37601), [CVE-2022-37603](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37603) and [CVE-2022-37599](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37599)

## v5.5.3 2022 November 17

- By default, sort invoices by date in the admin list
- Fix a bug: unable to reserve a machine with payment on site
- Fix a security issue: updated loader-utils to 1.4.2 to fix [CVE-2022-37601](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37601), [CVE-2022-37603](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37603) and [CVE-2022-37599](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37599)

## v5.5.2 2022 November 16

- Fix a bug: unable to export statistics

## v5.5.1 2022 November 15

- Fix a bug: free disk space not verified in some cases
- Fix a bug: unable to merge an SSO account with an existing account
- Fix a security issue: updated loader-utils to 1.4.1 to fix [CVE-2022-37601](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-37601)
- Fix a security issue: updated minimatch to 3.1.2 to fix [CVE-2022-3517](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-3517)

## v5.5.0 2022 November 08

- Feature Fablab Store
- Feature Allow admin to reserve for himself
- Allow searching by username (#401)
- Fix a bug: adding a new event without updating the dates results in internal server error (undefined method `div' for nil)
- Fix a bug: portuguese time formatting (#405)
- Fix a bug: admin users groups being overriden by SSO group_id (#404)
- Fix a bug: no statistics on trainings and spaces reservations
- Fix a bug: invalid ventilation for amount coupons
- Fix a bug: invalid VAT for invoices using amount coupons
- Fix a bug: invalid 1 cent rounding for invoices using coupons
- Fix a bug: plans list error when there was no plan for the user's group
- Fix a security issue: updated nokogiri to 1.13.9 to fix [GHSA-2qc6-mcvw-92cw](https://github.com/advisories/GHSA-2qc6-mcvw-92cw)
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2021,6]`
- [TODO DEPLOY] `rails fablab:setup:set_admins_group`

## v5.4.25 2022 October 19

- Fix a bug: unable apply a coupon if this coupon has used by an user removed
- Improved automated test on prepaid pack

## v5.4.24 2022 October 14

- Fix a bug: unable debit hours of prepaid pack after a reservation of machine

## v5.4.23 2022 October 12

- Fix a bug: unable to build docker image
- Fablab's store module
- Fix a bug: missing translations in PayZen configuration screens
- Fix a bug: wrong translation key prevents the display of the schedule deadline's payment mean
- [TODO DEPLOY] `rails db:seed`

## v5.4.22 2022 October 10

- Fix a bug: erroneous statistics
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2021,6]`

## v5.4.21 2022 October 05

- Ability to dismiss a user to a lower privileged role
- Fix a bug: unable to generate statistics
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2022,08]`

## v5.4.20 2022 September 27

- Fix a bug: unable to show the daily view of the public agenda, if it contains trainings or events
- Fix a bug: plan's categories descriptions are not shown
- Fix a bug: groups without plans are shown but empty
- Fix a bug: unable to display the payment schedules management interface

## v5.4.19 2022 September 13

- Fix a bug: computing the wallet amount to debit ignores the applied coupon

## v5.4.18 2022 September 12

- Script to download translations from Crowdin
- Fix a bug: admin and managers can't cancel or move event reservations
- Fix a bug: phone numbers with hyphens and spaces prevent profile completion when the data is provided by an SSO
- Fix a bug: unable to complete profile from SSO when the account validation is enabled

## v5.4.17 2022 September 06

- OpenAPI spaces endpoints (index/show)
- OpenAPI plans endpoints (index/show)
- OpenAPI plans categories index endpoint
- OpenAPI prices index endpoint
- Export used coupon (if any), in the reservations export
- Improved automated test on statistics generation
- Refactored statistics generation
- Refactored test helpers
- Script to upload translations sources to Crowdin
- Fix a bug: unable to generate statistics
- Fix a bug: the automated test on statistics generation was not running
- Fix a bug: the events times are not displayed
- Fix a security issue: disable log4j format message lookup by default for new installations
- Fix a security issue: updated omniauth to 1.9.2 to fix [CVE-2020-36599](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-36599)
- Fix a security issue: updated moment-timezone to 0.5.35 to fix [GHSA-v78c-4p63-2j6c](https://github.com/advisories/GHSA-v78c-4p63-2j6c) and [GHSA-56x4-j7p9-fcf9](https://github.com/advisories/GHSA-56x4-j7p9-fcf9)
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2022,07]`

## v5.4.16 2022 August 24

- Updated user's manual for v5.4 (fr)
- Updated portuguese translations
- Added automatic RuboCop validation on pre-commit
- Use union type instead of enum for SettingName
- Clarified documentation about default values for environment variables
- Updated documentation about the minimum RAM required (#385)
- Fix a bug: wrong variable reference in `SingleSignOnConcern:Merge_form_sso`
- Fix a bug: wrong focus behavior on text editor
- Fix a bug: trainings monitoring is not available
- Fix a bug: invalid password length verification in profile edition form
- Fix a bug: invalid password verification in setup script
- Fix a bug: during setup, unable to chown the installation folder, if the current user does not have a self-named group
- Fix a bug: during setup, the current value in config/env is not shown
- Fix a bug: disabling/removing a group has side effects on other groups

## v5.4.15 2022 August 1

- Improved security: adds redis-session-store to store session
- Improved security: makes rmagick, minimagick and mime types less explicit
- Improved security: add complexity check of the user password
- Improved security: prevents users enumeration attacks by not giving any info about the validity of the email

## v5.4.14 2022 August 1

- Added a test for multiple reservations on the same space slot
- Display the tag and theme field on the detail view of a project
- Improved file validation, validation is now based on content of the file in addition of the validation of the extension
- Fix a security issue: xss vulnerability in projects
- Fix a security issue: updated moment to 2.29.4 to fix [CVE-2022-31129](https://cve.mitre.org/cgi-bin/cvename.cgi?CVE-2022-31129)

## v5.4.13 2022 July 27

- Improved calendars loading time
- Refactored and documented the availability-slot-reservation data model
- Display bookers names to connected users now apply to all resources
- Updated rails locales files
- Usage of the rails logger instead of printing to standard output
- Optionnaly add a username column to the member list (#375)
- Improved attached ICS file texts, in reservations emails
- Fix a bug: user validation required alert is displayed and disappears instantly
- Fix a bug: canceled trainings are still shown on the public profile page
- Fix a bug: prevent same slot booking feature ignores canceled reservations
- Fix a bug: wrong currency on invoices files
- Fix a bug: unable to reserve if user's subscription plan is disabled
- Fix a bug: for admins and managers, the current password is not requested before changing their own password
- Fix a bug: missing translations
- Fix a bug: unable to book a space's slot with an existing reservation
- Fix a bug: Unable to import accounts from SSO when the transformation modal was opened but leaved empty
- Fix a bug: Unable to change the group of a user
- Fix a bug: As admin, unable to create a new member (#374)
- Fix a bug: profile completion form is not shown is T&C were not filled
- Fix a bug: Erroneous "cancelation failed" message if elasticsearch was disabled
- Fix a bug: admin group being replaced in SSO authentication (#376)
- Fix a bug: SSO data being overridden when it is empty and the user can change it (#377)
- Fix a security issue: updated terser to 4.8.1 to fix [CVE-2022-25858](https://cve.mitre.org/cgi-bin/cvename.cgi?CVE-2022-25858)
- Fix a security issue: updated tzinfo to 1.2.10 to fix [CVE-2022-31163](https://cve.mitre.org/cgi-bin/cvename.cgi?CVE-2022-31163)
- Fix a security issue: updated rails to 5.2.8.1 to fix [CVE-2022-32224](https://cve.mitre.org/cgi-bin/cvename.cgi?CVE-2022-32224)

## v5.4.12 2022 July 06

- Fix a bug: Gender, Address and Birthday are not mapped properly from SSO (#365)
- Fix a bug: unable to import a new account from an SSO provider
- Fix a security issue: updated rails-html-sanitizer to 1.4.3 to fix [CVE-2022-32209](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-32209)

## v5.4.11 2022 July 06

- Fix a bug: social networks icons not shown in firefox
- Fix a bug: Gender, Address and Birthday are not mapped properly from SSO (#365)
- Fix a bug: OIDC scopes are not shown in the configuration form select
- Fix a bug: OIDC scopes are not saved

## v5.4.10 2022 July 05

- Increased About page title's size
- Fix a bug: script mount-proof-of-identity-files creates a volume with an invalid path
- Fix a bug: unable to access the new OIDC provider form

## v5.4.9 2022 June 29

- Fix a bug: validator of reservation can't find if slot has reserved by reservable type

## v5.4.8 2022 June 29

- My reservations dashboard
- Display reservations credits in the dashboard
- Added a test case for space reservation
- Updated Portugueses translations (thanks to [@ghabreu](https://github.com/ghabreu))
- Improved explanations about members CSV imports
- Fix a bug: unable to reserve a space
- Fix a bug: invalid users are reported in search

## v5.4.7 2022 June 29

- Removed the admins' button to scroll to the featured event

## v5.4.6 2022 June 27

- Fix a bug: unable to run yq in deployment scripts

## v5.4.5 2022 June 27

- Feature the next event in the event page
- Documentation for installing behind a proxy
- Ability to install behind a proxy
- Improved docker image building time
- Use relative paths in mount scripts
- Run the docker image with the system user
- During the setup, autoconfigure the main domain
- During the setup, ask to set ALLOW_INSECURE_HTTP if DEFAULT_PROTOCOL was set to http
- Override angular currency filter, use Intl.NumberFormat to format amount
- Added some eslint rules to validate react components code style
- Fixed all react components code according to eslint rules
- Renamed proof-of-identity to supporting-documents in react components and in end-user strings
- Use bat to display coloured documentation of environment variables during setup
- Check the minimum docker version (20.10) during setup and upgrade
- Fix a bug: when email was mapped from SSO provided as empty string -> unable to merge account
- Fix a bug: when an empty data was retured by the SSO, unable to edit it
- Fix a bug: user can change his group in the profile completion page, even if mapped from the SSO
- Fix a bug: the birthdate was not marked as required, in the profile edition form
- Fix a bug: when the phone or the address were required, they were not marked as this, in the profile edition form
- Fix a bug: the birthday was not shown in user edition form
- Fix a bug: canceled event label's translation
- Fix a bug: unable to set the twitter input empty
- Fix a bug: unable to edit an event
- Fix a bug: times are not shown in admin/events monitoring page
- Fix a bug: unable to generate the secret key base during the setup
- Fix a bug: error message during the setup: the input device is not a TTY
- Fix a bug: when Fab-manager was installed as non-root user, unable to compile the assets during the upgrade
- Fix a bug: unable to remove an SSO data mapping field once saved
- Fix a bug: unable to update the user profile after toggling the organization switch twice
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/set-docker-user.sh | bash`

## v5.4.4 2022 June 8

- Check shopping cart items are valid before online payment
- Updated sidekiq-unique-jobs to 7.1.23 to get rid of Sidekiq's default_worker_options deprecation warning
- Allow moving with arrows in the setup script's inputs
- Ability to ignore assets compilation errors in the upgrade script
- Fix a bug: admins are shown in select member for reservation by admin
- Fix a bug: unable to show tours in machines and spaces page
- Fix a bug: unable to connect with OAuth2
- Fix a bug: when installing fab-manager as non-root user, most of the resulting installation directories were owned by root
- Fix a bug: unable to edit OIDC provider
- Fix a bug: list of OIDC scopes are loading indefinitely
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/use-relative-paths.sh | bash`

## v5.4.3 2022 June 6

- Updated translations
- Fix a bug: deprecated bundler arguments (#362)
- Fix a bug: unable to compile the assets when OIDC is enabled but the scopes were not set

## v5.4.2 2022 June 1

- Updated react-select to 5.3.2
- Moved the calendar navigation buttons to the left side
- Fix a bug: unable to remove the last training or the last tag to a member
- Fix a bug: unable to run scripts on systems with legacy version of docker-compose
- Fix a bug: unable to sign up if admin actived organization's additional fields with required
- Fix a bug: undefined error in new member page
- Fix a bug: OIDC scopes are separated by spaces, not commas
- Fix a bug: unable to create OIDC custom scopes
- Fix a bug: enable admins to be invited to collaborate on projects
- Fix a bug: hide some links to create an account if public registrations is disabled
- Fix a bug: unable to save user validation if admin click save user profile button after switch user valitation
- Fix a bug: if multi VAT no value is filled in, the general rate can't apply
- Fix a security issue: updated rack to 2.2.3.1 to fix [CVE-2022-30123](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-30123) and [CVE-2022-30122](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-30122)

## v5.4.1 2022 May 23

- Disable to clicking outside or pressing escape to close sign up modal
- Ability to disable colorize logging (#345)
- Detect assets compilation issue during the initial setup
- Fix a bug: when machines module disabled, Associated machines is still shown in trainings list
- Fix a bug: script mount-proof-of-identity-files unable to modify docker-compose.yml
- Fix a bug: Event reservation calendar encoding in mail
- Fix a bug: Missing of description of PlanCategory migration
- Fix a bug: Unable to create plans for all group
- Fix a bug: backPrevLocation button on Notification Center opens reset password page (#348)
- Fix a bug: compatibility with the new docker-compose CLI (#355)
- Fix a security issue: updated moment.js to 2.29.2. to fix [CVE-2022-24785](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24785)
- Fix a security issue: updated nokogiri to 1.13.6 to fix [CVE-2022-298240](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-298240)
- Fix a security issue: updated async to 2.6.4 to fix [CVE-2021-43138](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-43138)

## v5.4.0 2022 May 12

- Option to disable the 'machines' module
- Option to prevent users from changing their group
- Ability to define social networks for the FabLab "about page"
- Plan categories can have rich-text descriptions
- Improved security when changing passwords
- Support for OpenID Connect in Single-Sign-On authentication providers
- ICS file attached to the reservation notification email
- Refactored the user profile edition form
- Improved the profile completion page
- When generating an avoir, the option "by_wallet" is not present anymore if wallet module is disabled
- No longer needed to recompile the assets when switching the authentication provider
- Updated the documentation about the minimum docker version
- Updated nodejs version to 16.13.2 for dev environment, to reflect production version
- Changed the apparence of the modal dialogs (React): no more logo and the close button appears in full-text in the top right corner.
- Use react-hook-form to manage and validate forms
- Use of CSS variables for main and secondary colors in react components styles
- New text editor
- Change font family to "Work Sans"
- Updated eslint to v8 and eslint related packages to their latest versions
- Updated typescript to v4.6.3
- Updated react-select to v5.2.2
- Updated sidekiq-scheduler to v4.0.0
- Updated icalendar to 2.7.1
- Webpack overlay will now report eslint issues
- Linted all code according to eslint rules
- Fix a bug: when enabled, the statistics module is still not shown in the menu
- Feature User validation, an option for allow admin validate account of user to active/disable the reservation
- Feature Proof of identity by group, allow user upload his proof of identity and admin can check it for validate the account of user
- Feature Organization custom fields
- Fix a bug: Refused to connect to 'wss://localhost:3035/ws' when using a https tunnel in development mode
- Fix a bug: edge case of birthday in the future in seeds.rb, we should use Date.current instead of DateTime.current since birthday is a date (see https://github.com/sleede/fab-manager/issues/344)
- Fix a security issue: updated ruby to 2.6.10 to fix [CVE-2022-28739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-28739)
- Fix a security issue: updated rails to 5.2.7.1 to fix [CVE-2022-22577](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-22577) and [CVE-2022-27777](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-27777)
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`
- [TODO DEPLOY] add the `MAX_PROOF_OF_IDENTITY_FILE_SIZE` environment variable (see [doc/environment.md](doc/environment.md#MAX_PROOF_OF_IDENTITY_FILE_SIZE) for configuration details)
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/mount-proof-of-identity-files.sh | bash`
- [TODO DEPLOY] `rails db:migrate`
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] -> (only dev) `bundle install`

## v5.3.13 2022 May 02

- Fix a bug: With PayZen, when there was more than one transaction (for ex: 1 failed atempt + 1 successful atemp), the order was not considered PAID because only the first transaction was checked

## v5.3.12 2022 April 20

- Auto sync projects to OpenLab if set openlab_app_id and openlab_app_secret
- Fix a bug: back bouton can't return to previously page in projects page (list/new/show/edit)
- Fix a bug: OpenLab duplicate projects, if you are using OpenLab Projects, please follow the following TODO DEPLOY
- Fix a security issue: updated async to 2.6.4 to fix [CVE-2021-43138](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-43138)
- [TODO DEPLOY] `rails fablab:openlab:bulk_export`
- [TODO DEPLOY] wait 1 minute
- [TODO DEPLOY] `rails fablab:openlab:bulk_update`

## v5.3.11 2022 April 15

- Fix a bug: unable to send notification mail if no set a logo
- Fix a bug: unable to switch OpenLab projets
- Fix a bug: miss smtp tls in secrets.yml
- Fix a bug: unable to show projets whom user take part in
- Fix a security issue: updated puma to 4.3.12 to fix [CVE-2022-24790](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24790)
- Fix a security issue: updated moment to 2.29.2 to fix [CVE-2022-24785](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24785)
- Fix a security issue: updated nokogiri to 1.13.4 to fix [CVE-2022-24839](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24839), [CVE-2018-25032](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-25032), [CVE-2022-24836](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24836) and [CVE-2022-23437](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23437)

## v5.3.10 2022 April 12

- Updated generate invoice reference method
- Set invoice reference is required
- Fix a bug: unable to show machine availability slot for admin
- Fix a bug: unable to confirm modification of reservation for client
- Fix a bug: unable to show deleted user in reservation slot
- Fix a bug: race condition on invoice after payment (concerning payment schedules) https://app.clickup.com/t/25zpmn1
- Fix a bug: form maxlength count to exclude spaces and newline

## v5.3.9 2022 April 01

- Optimise sql query, avoid to N+1
- Fix a security issue: updated ansi-regex to 4.1.1 to fix [CVE-2021-3807](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-3807)
- Fix a bug: unable to show payment modal for stripe

## v5.3.8 2022 March 29

- Fix a bug: unable to show payment schedules list if active PayZen
- Fix a bug: unable to set user's invoicing profile names and email if active address required in create user form
- Fix a security issue: updated ruby to 2.6.9 to fix [CVE-2021-31810](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-31810), [CVE-2021-32066](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32066) , [CVE-2021-31799](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41817), [CVE-2021-31799](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41817) and [CVE-2021-41819](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41819)
- [TODO DEPLOY] `rails fablab:fix:invoices_without_names_and_email`

## v5.3.7 2022 March 28

- Updated Spanish translations (thanks to [@altieriranedo](https://crowdin.com/profile/altieriranedo))
- Fix a security issue: updated minimist to 1.2.6 to fix [CVE-2021-44906](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44906)
- Fix a security issue: updated node-forge to 1.3.0 to fix [CVE-2022-24771](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24771), [CVE-2022-24772](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24772) and [CVE-2022-24773](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24773)

## v5.3.6 2022 March 24

- Support for Google Analytics V4
- OAuth2 scopes are now configurable from the interface
- Prepaid-packs purchases are exported to the accounting CSV file
- Updated environment documentation
- Updated react-i18next to 11.15.6
- Updated i18next to 21.6.13
- Updated i18next-icu to 2.0.3
- Updated sidekiq-unique-jobs to 7.1.15
- Updated @uirouter/angularjs to 1.0.30
- Updated bootstrap-sass to 3.4.3
- Removed unmaintained gem sidekiq-cron and replaced it with sidekiq-scheduler
- Removed unmaintained @rails/webpacker v5 and replaced it with shakapacker v6.2.0
- Removed dependency to auto-ngtemplate-loader
- Updated deprecated division operators in sass
- Fix a bug: prepaid-packs purchases are reported as subscriptions in the statistics
- Fix a bug: error Couldn't find the binary git during assets compilation
- Fix a bug: a sentence was not linked to a translation key
- Fix a bug: the version check may be scheduled at an invalid time
- Fix a bug: the moment-timezone relied on an outdated version of moment with a case-sensitive locale file
- Fix a bug: unable to delete an administrator who had closed an accounting period
- Fix a bug: captcha keys are not shown in the admin panel, once configured
- Fix a bug: help message in upgrade script has a bogus format
- Fix a security issue: removed message format in elasticsearch's log4j to fix [CVE-2021-44228](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44228)
- Fix a security issue: updated image_processing to 1.12.2 to fix [CVE-2022-24720](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-24720)
- Fix a security issue: updated url-parse to 1.5.10 to fix [CVE-2022-0686](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0686), [CVE-2022-0691](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0691), [CVE-2022-0639](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0639) and [CVE-2022-0512](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0512)
- Fix a security issue: updated rails to 5.2.6.3 to fix [CVE-2022-21831](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-21831), [CVE-2022-23633](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23633)
- Fix a security issue: updated sidekiq to 6.4.1 to fix [CVE-2022-23837](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23837)
- Fix a security issue: updated nokogiri to 1.13.3 to fix [CVE-2021-30560](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-30560) and [CVE-2022-23308](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23308)
- Fix a security issue: updated puma to 4.3.11 to fix [CVE-2022-23634](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23634)
- Fix a security issue: updated i18next-http-backend to 1.3.2 to fix [CVE-2022-0235](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0235)
- Fix a security issue: updated follow-redirects to 1.18.8 to fix [CVE-2022-0536](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0536)
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2021,07]`
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/cve-2021-44228.sh | bash`
- [TODO DEPLOY] update your oAuth2 provider configuration with the scopes previously defined in the OAUTH2_SCOPE environment variable

## v5.3.5 2022 March 02

- Added [an option](doc/environment.md#OPENLAB_SSL_VERIFY) to allow set verify ssl option for OpenLab

## v5.3.4 2022 March 01

- Fix line break on home events' cards
- Fix typo "projets" => "projects"
- Removes dead code about OpenAPI (open_api_calls_count_tracings)
- Fix a bug: unable to modify OpenLab url for production

## v5.3.3 2022 February 08

- Updated german translations
- Fix a bug: unable to rebuild the statistics
- Fix a bug/regresion: $sce.getTrustedHtml removes all dangerous html like iframe (youtube players, ect), replaced by $sce.trustAsHtml which trusts the content, it creates a security breach but all contents are created by users to we trust them
- Fix a bug: in SubscriptionPolicy#show?, was causing an error notice, making user think that the payment was not done, but it was
- Fix a bug: destroying a project was impossible
- Fix a bug: fix non-blocking js error when there was not payment gateway set
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2020,04]`

## v5.3.2 2022 January 19

- Add a test for statistics generation
- Fix a bug: missing the Other payment method
- Fix a bug: do not display an untranslated string if a prepaid pack has no maximum validity
- Fix a bug: statistics not built for instances with plans created before v4.3.3
- Fix a bug: when requesting to send the sso migration code, the email was case-sensitive
- Fix a bug: the adminsys email was case-sensitive
- Fix a bug: members are unable to buy prepaid-packs by wallet
- Fix a bug: prepaid-packs without expiration date do not work
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2020,04]`

## v5.3.1 2022 January 17

- Definition of extended prices for spaces is now made in hours (previously in minutes)
- Support for JSONPath syntax in OAuth2 SSO fields mapping
- Basic support for OAuth2 scopes through an environment variable
- Ability to enable debug logs for the SSO authentication process using `SSO_DEBUG=true`
- Remove case sensitivity for the SSO account mapping process
- Ability to cancel a payement schedule from the interface
- Ability to create slots in the past
- Ability to disable public account creation
- Ability to select "bank transfer" as the payment mean for a payment schedule
- When a payment schedule was canceled by the payment gateway, alert the users
- When a payment schedule is in error, alert the users
- When a payment schedule is in error or canceled, ability to re-enable it with another payment method
- Fix card image ratio
- Update events heading style
- Update some icons
- Optimized the load time of the payment schedules list
- Optimized multiple DB queries
- Updated caniuse db
- Fix a bug: do not load Stripe if no keys were defined
- Fix a bug: some links redirect to the home page instead of triggering the requested action
- Fix a bug: exports to Excel are corrupted (#49)
- Fix a bug: if a specialized VAT rate was defined when the VAT was disabled, the resulting VAT rate is wrong
- Fix a bug: unable to rebuild the PDF for invoices without subscriptions
- Fix a bug: the switch to enable/disable the VAT does not reflect the current state of the VAT
- Fix a bug: SSO configuration interface has a misnamed field (Common URL)
- Fix a bug: unable to bind Profile.birthday and Profile.gender from an SSO
- Fix a security issue: updated follow-redirects to 1.14.7 to fix [CVE-2022-0155](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0155)
- [TODO DEPLOY] `rails db:seed`

## v5.3.0 2021 December 29

- Ability to configure multiple VAT rates, per kind of invoiced item
- Ability to export the collected VAT, by rates, to a CSV file
- Refactored the extended prices' frontend code to allow future customization
- Fix a bug: the amount label in not correctly shown in the extended prices modal
- Fix a bug: `extended_prices_in_same_day` apply the extended prices to each day

## v5.2.0 2021 December 23

- Ability to configure prices for spaces, by time slots different from the default hourly rate
- Updated portuguese translation
- Refactored the ReserveButton component to use the same user's data across all the component
- First optimization the load time of the payment schedules list

## v5.1.13 2021 November 16

- Fix a bug: unable to run the setup/upgrade scripts as root

## v5.1.12 2021 November 10

- Added an automated test on the plan creation endpoint
- Fix a bug: unable to create a plan

## v5.1.11 2021 October 22

- Refactored subscription new/renew/free extend interfaces and API
- Ability to configure the data sources of the booking prevention on overlapping slots
- Updated the production documentation
- Updated the SSO documentation
- Improved the stripe subscription process with better error handling
- The upgrade script will check and report the ability to access the hub API
- Fix a bug: canceled training reservation is not marked as this in admin > edit members > trainings
- Fix a bug: users can set their birthdate in the future
- Fix a bug: the upgrade script won't add anymore the environment variables that are already present
- Fix a bug: admin cannot take or renew a subscription for a member from member/edit interface
- Fix a bug: missing translations
- Fix a bug: the upgrade script report an invalid version to upgrade to
- Fix a bug: invalid amount provided to the PayZen payment gateway, when using a 0-decimal or a 3-decimal currency
- Fix a bug: incorrect behavior for the setting "email confirmation required"
- Fix a bug: invalid text shown when a member confirms a free cart
- Fix a bug: 3DS confirmation is not asked when an admin is subscribing a user through a payment schedule, using PayZen
- Updated @rails/webpacker to 5.4.3
- Updated react-refresh-webpack-plugin to 0.5.1
- Updated react-refresh to 0.10.0
- Fix a security issue: updated tar to 6.1.11 to fix [CVE-2021-37712](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-37712), [CVE-2021-37701](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-37701) and [CVE-2021-37713](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-37713)
- Fix a security issue: updated immer to 9.0.6 to fix [CVE-2021-3757](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-3757) and [CVE-2021-23436](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23436)
- Fix a security issue: updated url-parse to 1.5.3 to fix [CVE-2021-3664](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-3664)
- Fix a security issue: updated axios to 0.21.2 to fix [CVE-2021-3749](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-3749)
- Fix a security issue: updated nokogiri to 1.12.5 to fix [CVE-2021-41098](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41098)
- Fix a security issue: updated puma to 4.3.9 to fix [CVE-2021-41136](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41136)
- Fix a security issue: updated sidekiq to 6.2.1 to fix [CVE-2021-30151](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-30151)
- [TODO DEPLOY] `rails db:seed`

## v5.1.10 2021 October 04

- Fix a bug: the image of the about page is not using the image set in the backoffice
- Fix a bug: updated sassc to 2.4.0 to fix ruby runtime error on some CPU architectures (#270)
- Fix a security issue: prevent HTML code edition in projects, to prevent XSS vulnerability (#293)
- Fix a bug: cover image doesn't display in profile
- Fix a bug: fab-manager redirects to the home page when we delete a machine photo

## v5.1.9 2021 September 21

- Add a setting to restrict the purchase and use of a prepaid pack to users with a valid subscription
- Fix a bug: unable to view the plans names in the reservation calendar
- Fix a bug: label name of the book overlapping slot setting

## v5.1.8 2021 September 13

- Improved stripe 3D secure payment on payment schedules
- Disable monthly payment for the subscription with interval 1 month
- Fix a bug: unable to show statistics module in nav menu after login
- Fix a bug: plans page show an error if admin don't create any plans

## v5.1.7 2021 August 24

- Updated Norwegian language
- Fix a bug: unable to show plans list page

## v5.1.6 2021 August 6

- Adjust packs pricing popover position
- Updated Norwegian language
- Updated addressable from 2.7.0 to 2.8.0
- Updated tar from 6.1.0 to 6.1.4
- Fix a bug: unable to generate avoir of wallet
- Fix a bug: managers can't reserve trainings for users

## v5.1.5 2021 August 2

- Fix a bug: unable to show statistics
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2021,6]`

## v5.1.4 2021 July 9

- Fix a bug: stripe 3D Secure payment

## v5.1.3 2021 July 2

- Fix a bug: missing hour format for norwegian
- Fix a bug: missing invoice watermark for norwegian
- Fix a bug: prepaid hours not used if bought slot is longer than remaining prepaid time
- Fix a bug: cookies modal buttons are too small
- Fix a bug: do not include fully used packs in user's packs

## v5.1.2 2021 July 2

- Fix a bug: invalid rails locale for Norwegian

## v5.1.1 2021 July 1st

- Set up the linter for Typescript files
- Disable SQL format for the schema
- Fix a bug: config norwegian locale

## v5.1.0 2021 July 1st

- Prepaid packs of hours for the machines
- Tests for OpenAPI user trainings
- Norwegian language
- Fix a bug: unable to filter by multiple user IDs in OpenAPI
- Fix a bug: do not display two empty categories in the plan creation form
- Fix a bug: do not return to the home page when clicking on previous in the machine description page
- Fix a bug: public list of plans fails to render if a group has no plans
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v5.0.14 2021 September 30

- Fix a bug: unable to show plan name in calendar reservations
- Fix a bug: book overlapping slot setting labal name

## v5.0.13 2021 September 13

- Improved stripe 3D secure payment on payment schedules
- Disable monthly payment for the subscription with interval 1 month
- Fix a bug: unable to show statistics module in nav menu after login
- Fix a bug: plans page show an error if admin don't create any plans

## v5.0.12 2021 August 24

- Fix a bug: unable to show plans page

## v5.0.11 2021 August 6

- Fix a bug: unable to generate avoir of wallet
- Fix a bug: manager can't reserve any training for users

## v5.0.10 2021 August 2

- Fix a bug: unable to show statistics
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_statistics[2021,6]`

## v5.0.9 2021 July 9

- Fix a bug: stripe 3D Secure payment

## v5.0.8 2021 June 28

- Ability to run `fablab:chain:all` non interactively
- Full test coverage of the OpenAPI
- Fix a bug: unable to get the Events without images from the OpenAPI
- Fix a bug: unable to get the Space reservations from the OpenAPI
- Fix a bug: unable to get invoices from the OpenAPI

## v5.0.7 2021 June 24

- Fix a bug: unable to export members list if no subscriptions was taken
- Fix a bug: most OpenAPI endpoints were dysfunctional
- Fix a bug: unable to open some modals when the logo was undefined
- Fix a bug: stripe subscription generation fails if the user already has a subscription

## v5.0.6 2021 June 21

- Updated babel and its dependencies to 7.14.5 / 7.14.6
- Updated @stripe/stripe-js to 1.15.1
- Updated @types/node to 15.12.2
- Updated @types/react-dom to 17.0.6
- Updated @types/react to 17.0.11
- Updated chokidar to 3.5.2
- Updated codemirror to 5.62.0
- Updated convert-source-map to 1.8.0
- Updated core-js-compat to 3.15.0
- Updated electron-to-chromium to 1.3.752
- Updated immer to 9.0.3
- Updated jquery-ujs to 1.2.3
- Updated react-i18next to 11.11.0
- Updated react-modal to 3.14.3
- Updated readdirp to 3.6.0
− Updated regexpp to 3.2.0
- Updated resolve-url-loader to 4.0.0
- Updated sass to 1.35.1
- Updated tslib to 2.3.0
- Updated typescript to 4.3.4
- Fix a bug: unable to sync coupons on stripe
- Fix a security issue: updated postcss to 7.0.36 to fix [CVE-2021-23368](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23368)

## v5.0.5 2021 June 18

- Fix a bug: during the upgrade, unable to detect the target when not explicitly specified
- Fix a bug: unable to sync users on stripe if one of them have an invalid email address
- Fix a bug: unable to book a free event
- Fix a bug: can't see the dates for the next booked training session, when the user is reserving a machine without the appropriate training
- Fix a bug: invalid link to the user's manual
- Fix a bug: unable to sync coupons on stripe
- Fix a bug: ignored coupon when booking an event with card payment
- Fix a bug: deleting a coupon displays an error message

## v5.0.4 2021 June 15

- Ability to disable the public agenda
- Display the category in the plans list
- Do not display the type in the plans list
- Updated medium-editor to v5 and angular-medium-editor accordingly
- Fix a bug: a message tells that creating a new plan fails, but it worked
- Fix a bug: unable to select no category in plan creation/edition after a category selection
- Fix a bug: the training validation modal shows cancelled trainings
- [TODO DEPLOY] `rails db:seed`

## v5.0.3 2021 June 14

- Updated user's manual for v5
- Improved test coverage on payment schedules
- Fix a bug: unable to process stripe payments with 3DS authentication
- Fix a bug: unable to book an event
- Fix a bug: unable to list user's payment schedules in the dashboard

## v5.0.2 2021 June 11

- Ability to upgrade to a specific version with the script
- Improved display when no plan-categories exists
- Updated VCR to 6.0.0
- Updated cassettes
- Automated stripe secrets filtering in cassettes
- Updated documentation diagrams

## v5.0.1 2021 June 10

- Updated upgrade instructions
- Fix a bug: unable to run interactive rails commands during the upgrade

## v5.0.0 2021 June 10

- Ability to use PayZen as the payment gateway
- Ability to organize plans in categories
- Ability to configure the prefix of the payment-schedules' files
- Filter plans by group and by duration
- For payment schedules, ability to update the related payment card before the deadline
- Refactored data architecture to a more generic shopping cart model
- Redesigned the data structure to allow buying multiple and various objects
- Updated React and its dependencies to 17.0.3 and matching
- Updated the dependencies of: webpack, lodash, eslint, webpack-dev-server, react2angular, auto-ngtemplate-loader, angular-bootstrap-switch, react-refresh-webpack-plugin and eslint-plugin-react
- Improved error handling in upgrade script
- Improved documentations
- Improved the style of the titles of the subscription page
- Check the status of the assets' compilation during the upgrade
- Generate footprints in a more reproductible way
- Task to reset the stripe payment methods in test mode
- Validate on server side the reservation of slots restricted to subscribers
- Unified and documented upgrade exit codes
- During setup, ask for the name of the external network and create it, if it does not already exists
- Fix a bug: cannot select the recurrence end date on Safari or Internet Explorer
- Fix a bug: build status badge is not working
- Fix a bug: unable to set date formats during installation
- Fix a bug: unable to cancel the upgrade before it begins
- Fix a bug: in the admin calendar, the trainings' info panel shows "duration: null minutes"
- Fix a bug: on the subscriptions page, not logged-in users do not see the action button
- Fix a bug: unable to map a new setup to the db network
- Fix a bug: do not allow users to register with an invalid email address
- Fix a security issue: updated dns-packet to 1.3.4 to fix [CVE-2021-23386](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23386)
- Fix a security issue: updated ws to 6.2.2 to fix [CVE-2021-32640](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32640)
- `SUPERADMIN_EMAIL` renamed to `ADMINSYS_EMAIL`
- `scripts/run-tests.sh` renamed to `scripts/tests.sh`
- [BREAKING CHANGE] GET `open_api/v1/invoices` won't return `stp_invoice_id` OR `stp_payment_intent_id` anymore. The new field `payment_gateway_object` will contain some similar data if the invoice was paid online by card.
- [BREAKING CHANGE] GET `open_api/v1/invoices` won't return `invoiced_id`, `invoiced_type` OR `invoiced.created_at` anymore. The new field `main_object` will contain the equivalent data.
- [TODO DEPLOY] before running the database migration (db:migrate), run: `rails fablab:chain:all`
- [TODO DEPLOY] `rails fablab:stripe:set_gateway`
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/rename-adminsys.sh | bash`

## v4.7.14 2021 September 30

- Fix a bug: update sassc to 2.4.0 to try to fix #270 (ruby runtime error on some CPU architectures)

## v4.7.13 2021 June 11

- Fix a bug: unable to process stripe payments with 3DS authentication

## v4.7.12 2021 June 09

- Fix a bug: unable to process stripe payments

## v4.7.11 2021 May 26

- Updated ffi to 1.15.1
- Updated GitHub issue templates
- Fix a bug: zero-decimal currencies were charged multiplied by 100
- Fix a bug: fablab:fix_invoices task fails to recreate the data if the date is in english

## v4.7.10 2021 May 25

- CAD lists of types and extensions are now ordered alphabetically
- Fix a bug: reservation of slots restricted to subscribers leads to invoices without invoiced_id
- Fix a bug: new installation with mapping to an external network does not connect fab-manager to elasticsearch
- Fix a bug: typo in allow/prevent booking overlapping slots
- Fix a bug: unable to use run.fab.mn
- Fix a bug: parse error while compiling the assets
- Fix a security issue: updated @rails/webpacker to 5.4.0 to fix [CVE-2021-28092](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28092) and [CVE-2021-23368](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23368)
- Fix a security issue: updated ruby to 2.6.7 to fix [CVE-2020-25613](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25613) and [CVE-2021-28965](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28965)
- Fix a security issue: updated puma to 4.3.8 to fix [CVE-2019-16770](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16770)
- Fix a security issue: updated nokogiri to 1.11.4 to fix [GHSA-7rrm-v45f-jp64](https://github.com/advisories/GHSA-7rrm-v45f-jp64)
- [TODO DEPLOY] `rails fablab:fix_invoices`
- [TODO DEPLOY] `rails fablab:maintenance:regenerate_invoices[year,month]` Depending on the status of the above command, you'll need to run that one for the months with erroneous invoices

## v4.7.9 2021 May 17

- Updated dependency to OpenLab
- Updated i18next to 19.9.3
- Prevent the worker from crashing if OpenLab is not reachable in dev
- Allow setting multiple themes for a single event
- Increased the width of the input field for the prices of the events
- Script to run a rails command with ease in production (`run.fab.mn`)
- Fix a bug: invalid currency in notifications for locales with region (eg. fr-CM)
- Fix a bug: the notification sent to the project author when a collaborator has confirmed his participation is not sent
- Fix a bug: the event themes are not kept when editing the event again
- Fix a bug: the count of successfully updated events was not correct
- Fix a bug: german watermark was missing
- Fix a bug: invoices are not generated in test/development for locale with region (eg. fr-CA)
- Fix a bug: cannot access to "about" page on small devices
- Fix a bug: "about" page shows a non-functional menu icon
- Fix a bug: responsiveness of the "about" page title
− Fix a bug: unable to change the slots durations for a new availability
- Fix a bug: some invoices does not have the name of the user
- Fix a bug: unable to sort invoices by date
- Fix a security issue: updated underscore to 1.12.1 to fix [CVE-2021-23358](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23358)
- Fix a security issue: updated lodash to 4.17.21 to fix [CVE-2021-23337](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23337)
- Fix a security issue: updated url-parse to 1.5.1 to fix [CVE-2021-27515](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-27515)
- Fix a security issue: updated hosted-git-info to 2.8.9 to fix [CVE-2021-23362](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23362)
- Fix a security issue: updated codemirror to 5.58.2 to fix [CVE-2020-7760](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-7760)
- Fix a security issue: updated rails to 5.2.6 to fix [CVE-2021-22904](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-22904)
- Fix a security issue: updated react-i18next to 11.8.15 to fix [CVE-2021-23346](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-23346)
- [TODO DEPLOY] `rails fablab:fix:invoices_without_names`

## v4.7.8 2021 April 02
- Updated mimemagic to 0.3.10 to fix [a build issue](https://github.com/mimemagicrb/mimemagic/issues/139)

## v4.7.7 2021 April 02
- Enforced validation on required input fields
- Updated babeljs and its dependencies
- Updated german translations (thanks to [@Piapat](https://crowdin.com/profile/piapat))
- Fix a bug: the view is not refreshed when deleting a recurring slot
- Fix a bug: unable to add a new authorized file type for project's CAD files
- Fix a bug: unable to update a coupon
- Fix a bug: create a training availability with calendar in month view result in wrong dates
- Fix a security issue: updated y18n to 4.0.1 to fix [CVE-2020-7774](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-7774)

## v4.7.6 2021 March 24
- Ability to disable the trainings module
- Ability to set the address as a mandatory field
- The address is now requested when creating an account
- The profile completion page is less fuzzy for people landing on it without enabled SSO
- Prevent showing error message when testing for old versions during upgrade
- In the email notification, sent to admins on account creation, show the group of the user
- More explanations in the setup script
- Send pre-compressed assets to the browsers instead of the regular ones
- Links created using "medium editor" opens in new tabs
- Improved style of public plans page
- Improved the upgrade script
- Fix a bug: subscriptions tab is selected by default in statistics, even if the module is disabled
- Fix a bug: select all plans for slot restriction (through the dedicated button) also selects the disabled plans
- Fix a bug: recurring availabilities are not restricted to subscribers
- Fix a bug: accounting exports may ignore some invoices for the first and last days
- Fix a bug: accounting export caching is not working
- Fix a bug: unable to run the setup script if sudoers belong to another group than sudo
- Fix a security issue: updated elliptic to 6.5.4 to fix [CVE-2020-28498](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-28498)
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/nginx-packs-directive.sh | bash`
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v4.7.5 2021 March 08
- Fix a bug: unable to compile the assets during the upgrade, if the env file has some whitespaces around the equal sign

## v4.7.4 2021 March 08
- Show remaining training credits in the dashboard
- Allow writing short rich descriptions for each subscription plan
- Allow inserting hyperlinks in customized info messages
- Use the primary color to display plans' price in the public view
- Do not close login modal when clicking on the backdrop
- Improved scripts for mounting volumes
- Increased verbosity of upgrade script
- Fix a bug: mounting the payment-schedules volume in the docker-compose file results in an invalid file
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v4.7.3 2021 March 03
- Improved the setup script
- Fix a bug: unable to install a new instance with an external reverse proxy
- Fix a bug: do not display "powered by disqus" if Disqus is disabled
- Fix a bug: do not send notifications each hour for payment schedules deadlines
- Fix a security issue: updated rails to 5.2.4.5 to fix [CVE-2021-22880](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-22880)
- [TODO DEPLOY] -> (only dev) `bundle install`

## v4.7.2 2021 March 1st
- Updated yq to v4
- Fix a bug: unable to upgrade using the easy upgrade command
- Fix a security issue: possible SQL injection when dropping the database
- Fix a security issue: restrict allowed keys when creating/updating credits
- [TODO DEPLOY] `rails fablab:openlab:bulk_export` if you have enabled OpenLab (projects sharing)

## v4.7.1 2021 February 24
- Fix a security issue: updated axios to 0.21.1 to fix [CVE-2020-28168](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-28168)

## v4.7.0 2021 February 23
- Payment schedules on subscriptions
- Refactored theme builder to use scss files
- Updated stripe gem to 5.29.0
- Architecture documentation
- Improved coupon creation/deletion workflow
- Default texts for the login modal
- Updated caniuse to 1.0.30001191
- Fix a bug: updated ffi to 1.14.2 to fix a segmentation fault with ruby 2.6.6
- Fix a bug: unable to access embedded plan views
- Fix a bug: warning message overflow in credit wallet modal
- Fix a bug: when using a cash coupon, the amount shown in the statistics is invalid
- Fix a bug: unable to create a coupon on stripe
- Fix a bug: no notifications for refunds generated on wallet credit
- Fix a bug: in staging environments, emails are not sent
- Fix a bug: unable to configure the app to use a german locale
- Fix a security issue: updated carrierwave to 2.1.1 to fix [CVE-2021-21305](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-21305)
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`
- [TODO DEPLOY] `rails fablab:stripe:set_product_id`
- [TODO DEPLOY] `rails fablab:stripe:sync_coupons`
- [TODO DEPLOY] `rails fablab:setup:add_schedule_reference`
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] add the `INTL_LOCALE` environment variable (see [doc/environment.md](doc/environment.md#INTL_LOCALE) for configuration details)
- [TODO DEPLOY] add the `INTL_CURRENCY` environment variable (see [doc/environment.md](doc/environment.md#INTL_CURRENCY) for configuration details)
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/mount-payment-schedules.sh | bash`
- [TODO DEPLOY] -> (only dev) `bundle install`

## v4.6.6 2021 February 02
- Full German translation (thanks to [@korrupt](https://crowdin.com/profile/korrupt))
- OpenAPI endpoints to create/update/show/delete machines
- Updated environment documentation
- Removed useless locales' configuration files
- OpenAPI's endpoints will now return more detailed error messages when something wrong occurs
- Fix a bug: when an event is modified, the member's reservations does not reflect the new event date
- Fix a security issue: updated ini to 1.3.8 to fix [CVE-2020-7788](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-7788)
- Fix a security issue: updated nokogiri to 1.11.1 to fix [CVE-2020-26247](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-26247)
- Updated caxlsx to 3.0.4, and the dependencies of caxlsx_rail
- [TODO DEPLOY] -> (only dev) `bundle install`

## v4.6.5 2020 December 07
- Fix a bug: unable to run the upgrade script with docker-compose >= v1.19

## v4.6.4 2020 December 1st

- Full Portuguese translation (thanks to [@gusabr](https://crowdin.com/profile/gusabr))
- Updated the version of ruby to 2.6.6
- Add the configuration of the postgreSQL username in environment variables
- Fix a bug: unable to build homepage custom stylesheet
- Fix some security issues: [CVE-2020-10663](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10663) and [CVE-2020-10933](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10933)
- [TODO DEPLOY] add `POSTGRES_USERNAME=postgres` to the environment variables (see [doc/environment.md](doc/environment.md#POSTGRES_USERNAME) for configuration details)

## v4.6.3 2020 October 28

- Enabled Typescript
- Enabled Hot module replacement
- Enlarged privacy policy display and edition zones
- Removed fab-manager email address from the seeds
- Initialize new plans with default prices for machines & spaces
- Display a message when no plans are available
- Fix a bug: in the settings' area, boolean switches are always shown as false
- Fix a bug: public cards presenting the plans in the public area, have bogus style
- Fix a bug: theme primary color is ignored on links
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v4.6.2 2020 October 23

- Add intermediate step version for upgrades: v4.4.6. This will prevent issues with FootprintDebug if a regeneration is needed
- Check postgreSQL status before compiling assets
- Improved the documentation about the upgrade process
- Fix a bug: unable to set libraries locales to their default values (en-us)
- Fix a bug: unable to display details about a closed period
- Fix a bug: members cannot view available trainings slots
- Fix a bug: availabilities not created at the same DST than the target date may be shifted in time

## v4.6.1 2020 October 21

- Reduced downtime during upgrades
- Architecture changes to allow including React.js components into the application
- Allow running upgrade scripts from dev ranch
- Fix a bug: script mount-webpack.sh was not updating the docker-compose.yml file
- Fix a security issue: updated resolve-url-loader to 3.1.2 to fix [CVE-2020-15256](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15256)
- Fix a security issue: updated selfsigned to 1.10.8 to fix [CVE-2020-7720](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-7720)

## v4.6.0 2020 October 20

- Migrated the assets build pipeline from Sprockets to Webpack
- Version check during the upgrade
- Fix a bug: changing the date of a training session does not prevent the selection of a different type of training
- Fix a bug: unable to change the date formats using the setup script
- Fix a bug: missing translation for projets drafts in public profile
- Fix a bug: email notification after reservation update have wrong previous date (#234)
- Fix a bug: unable to rename a group containing users
- Updated contribution guidelines
- Updated summernote to 0.8.18
- Updated angular-summernote to 0.8.1
- Updated FontAwesome from v4 to v5
- Updated jquery-minicolors to 2.3.5
- Updated angular-bootstrap-switch to 0.5.2
- Updated bootstrap-switch to 3.4.0
- Updated fullCalendar to 3.10.2
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/mount-webpack.sh | bash`

## v4.5.9 2020 September 29

- Ability to configure until when the events are shown on the home page
- Alert before cancelling a reservation that credits will be lost
- Improved documentation about upgrade process
- Fix a bug: managers cannot see passed events
- [TODO DEPLOY] `rails db:seed`

## v4.5.8 2020 September 28

- Fix a bug: unable to run the elastic-upgrade script
- Fix a security issue: updated rails to 5.2.4.4 to fix [CVE-2020-15169](https://nvd.nist.gov/vuln/detail/CVE-2020-15169)

## v4.5.7 2020 September 23

- Fix a bug: unable to run tests suite with run-tests.sh
- Fix a bug: unable to search for projects (#230)
- Fix a bug: wallet tab is not shown in members dashboard
- Fix a bug: slots duration is not shown when looking at a new availability
- Fix a bug: user's manual URL is not up-to-date
- Fix a bug: unable to create a subscription plan for only one group
- Fix a bug: removed unexpected character in coupon form
- Updated coveralls gem to a supported version

## v4.5.6 2020 September 1st

- Fix a bug: unable to pay by card for events reservation
- Fix a bug: unable to run task find_incoherent_invoices

## v4.5.5 2020 August 26

- Improved portuguese translations
- Fix a bug: unable to search for projects on OpenLab
- Fix a bug: erroneous translations in english (#226)

## v4.5.4 2020 July 29

- Display an asterisk on the phone input field, in the admin creation form, if the phone is configured as required
- Keep the history of footprints data for verification purposes
- Enhanced rake task to create fixtures for test cases
- Automated tests for exports
- Fix a bug: unable to export reservations
- Fix a bug: unable to export subscriptions
- Fix a bug: unable to receive mails in development
- Fix a security issue: updated json to 2.3.1 to fix [CVE-2020-10663](https://nvd.nist.gov/vuln/detail/CVE-2020-10663)
- [TODO DEPLOY] `rails db:migrate`
- [TODO DEPLOY] `rails fablab:maintenance:save_footprint_data`

## v4.5.3 2020 July 21

- Documentation of the easy upgrade procedure
- Fix a bug: unable to seed the database
- Fix a security issue: updated lodash to 4.17.19 to fix [lodash#4744](https://github.com/lodash/lodash/issues/4744)

## v4.5.2 2020 July 1st

- Fix a bug: unable to set stripe public key in production
- Fix a bug: health API is broken if ElasticSearch is not present
- Fix a bug: unable to sync members with stripe
- Fix a bug: version check is not working
- Fix a bug: enabling auth_provider from the tests happens twice in coverall context
- [TODO DEPLOY] `rails fablab:maintenance:clean_workers`

## v4.5.1 2020 July 1st

- Ability to run the upgrade without interactions
- Fix a bug: Unable to access the invoices section if no stripe key was set or incorrect
- Fix a bug: task env_to_db overrides the values set in the UI, even if the corresponding variable was not defined in the env file

## v4.5.0 2020 June 30

- Search in the projets directly from PostgreSQL
- Ability to configure most of the settings from the admin's UI
- Ability to lock some settings from the environment
- Improved display of the icons alerting about an outdated version
- Improved mime-type checking (back & front)
- Dependency to ElasticSearch is now optional, if you disable the statistics
- Updated CarrierWave to 2.1.0
- Updated redis to v6, with alpine image
- Updated Sidekiq to 6.0.7
- Updated documentation
- Beta preview of the upgrade script
- Fix a bug: managers do not see the name of the user who reserved a slot
- Fix a bug: OpenAPI documentation is not available
- Fix a bug: summary of create training availability shows incorrect alert about slot splitting
- Fix a bug: invalid URL redirection for SSO login
- Fix a security issue: updated websocket-extensions to 0.1.5 to fix [CVE-2020-7663](https://nvd.nist.gov/vuln/detail/CVE-2020-7663)
- Fix a security issue: updated angular.js to 1.8 to fix [CVE-2020-7676](https://nvd.nist.gov/vuln/detail/CVE-2020-7676)
- Fix a security issue: updated rack to 2.2.3 to fix [CVE-2020-8184](https://nvd.nist.gov/vuln/detail/CVE-2020-8184)
- [TODO DEPLOY] add the `POSTGRESQL_LANGUAGE_ANALYZER` environment variable (see [doc/environment.md](doc/environment.md#POSTGRESQL_LANGUAGE_ANALYZER) for configuration details)
- [TODO DEPLOY] `rails fablab:setup:env_to_db`
- [TODO DEPLOY] `rails db:seed`
- [TODO DEPLOY] `\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/redis-upgrade.sh | bash`
- [TODO DEPLOY] -> (only dev) upgrade redis to v6, you may be able to use the script above, depending on your installation

## v4.4.6 2020 June 01

- Fix a security issue: updated kaminari from 1.2.0 to 1.2.1 to fix [CVE-2020-11082](https://nvd.nist.gov/vuln/detail/CVE-2020-11082)

## v4.4.5 2020 May 27

- Fix a security issue: updated rails to 5.2.4.2 to fix [CVE-2020-8162](https://nvd.nist.gov/vuln/detail/CVE-2020-8162), [CVE-2020-8165](https://nvd.nist.gov/vuln/detail/CVE-2020-8165) and [CVE-2020-8166](https://nvd.nist.gov/vuln/detail/CVE-2020-8166)

## v4.4.4 2020 May 25

- Fix a security issue: updated puma from 3.12.4 to 3.12.6 to fix [CVE-2020-11077](https://nvd.nist.gov/vuln/detail/CVE-2020-11077) and [CVE-2020-11076](https://nvd.nist.gov/vuln/detail/CVE-2020-11076)

## v4.4.3 2020 May 25

- Fix a bug: recurrent availabilities do not keep the custom duration
- [TODO DEPLOY] `rails fablab:fix:availabilities_duration`

## v4.4.2 2020 May 19

- Upgraded to ruby 2.6.5
- Prevent admins from leaving their dedicated group
- Faraday was downgraded from 1.0 to 0.17 for better compatibility with elasticsearch-ruby 5 (#205 #196)
- Added [an option](doc/environment.md#ALLOW_INSECURE_HTTP) to allow usage in production without HTTPS
- Now using node.js instead of therubyracer for building javascript assets
- Removed dependency to has_secure_token to fix warnings about already initialized constant
- Fix a bug: when an admin logs on the subscription page, his view is broken
- Fix a bug: admin's members list shows the same members multiple times
- Fix a bug: when a new account is created through the sign-up modal, the role is not reported in the StatisticProfile (#196)
- Fix a bug: openAPI clients interface has a bugged behavior when creating/editing a client
- Fix a security issue: updated actionpack-page_caching from 1.1.0 to 1.2.2 to fix [CVE-2020-8159](https://nvd.nist.gov/vuln/detail/CVE-2020-8159)
- [TODO DEPLOY] `rails fablab:fix:role_in_statistic_profile`
- [TODO DEPLOY] `rails fablab:es:generate_stats[2019-06-13]` (run after the command above!)
- [TODO DEPLOY] -> (only dev) `rvm use && bundle install`

## v4.4.1 2020 May 12

- Prevent VersionCheckWorker from polluting the sidekiq stack in development
- Fix a bug: the subscription page is not available
- Fix a bug: users promoted to the administrator role are not in the admin group
- Fix a bug: menu separators are not visible
- [TODO DEPLOY] `rails fablab:maintenance:rebuild_stylesheet`

## v4.4.0 2020 May 12

- Manager: a new role between the member and the administrator
- The invoices list displays the operator in case of offline payment
- Interface to manage partners
- Ability to define, per availability, a custom duration for the reservation slots
- Ability to promote a user to a higher role (member > manager > admin)
- Ask for confirmation before booking a slot for a member without the required tag
- Corrected the documentation about BOOK_SLOT_AT_SAME_TIME
- Auto-adjusts text colors based on the selected theme colors
- Check password length during installation
- Fix a bug: accounting periods totals are wrong for periods closed after 2019-08-01
- Fix a bug: unable to change group if the previous was deactivated
- Fix a bug: unable to create events or trainings that are not multiples of SLOT_DURATION
- Fix a bug: unable to delete an unreserved event
- Fix a bug: "Free entry" label for events without reservation
- Fix a bug: updating a setting without any changes triggers an error
- Fix a bug: plan edition does not show the associated group
- Fix a bug: subscription page shows the groups without any active plans
- Fix a bug: cart price inconsistently updated after a subscription
- Fix a bug: background image of the profile is not shown and wrong menu hover color
- Fix a bug: do not show disabled groups and plans during availability creation
- Fix a security issue: updated jquery to fix [CVE-2020-11023](https://nvd.nist.gov/vuln/detail/CVE-2020-11023)
- [TODO DEPLOY] `rails db:migrate`

## v4.3.4 2020 April 14

- Improved version check
- Improved setup script for installations without nginx
- Changed some default values for new installations
- Database is now compatible with Fab-manager v1, to allow upgrades
- Updated documentation
- Changed In-Context pseudo-language to Zulu instead of Acholi
- Allow removing contacts from the about page
- Maintenance task to migrate notifications for Fab-manager v1
- Maintenance task to display the current version
- Now using MailCatcher with docker
- Fix a bug: installation without nginx does not remove the service from the docker-compose file
- Fix a bug: default twitter feed is invalid
- Fix a bug: default nginx configuration does not allows secure cookies
- Fix a bug: in-context translation is loading invalid locale for MessageFormat
- Fix a bug: invalid link to upgrade procedure
- Fix a bug: unable to access health endpoint
- Fix a bug: migration 20160704095606 cannot run due to GDPR refactoring
- Fix a bug: in-context translation is not working
- [TODO DEPLOY] -> (only dev) add mailcatcher to your [docker-compose.yml](docker/development/docker-compose.yml)

## v4.3.3 2020 April 1st

- Docker build will no longer embed development dependencies
- Updated instructions to set up a development environment
- Updated translations
- Removed `MESSAGEFORMAT_LOCALE` as it is now handled by make-plural
- Updated rails framework to v5.2
- Updated angular-translate
- Updated eslint
- Updated compass-rails & compass-core
- Renamed production documentation
- Syntax improvements in scss files
- Fix a bug: crediting a wallet w/ refund invoice prevent statistics generation (#196)
- Fix a bug: no statistics for subscriptions (#196)
- Fix a bug: invalid translation keys in closing accounting period interface
- Fix a bug: since PostgreSQL release 9.6.17, the new installations will fail to start complaining for missing password (#194)
- Fix a bug: missing translations for some error messages
- Fix a bug: invalid footprints in invoices fixtures
- Fix a bug: unable to export accounting data to ACD
- Fix a bug: report error on invalid encoding in members import
- Fix a bug: missing translation for subscriptions statistics > duration
- Fix a security issue: updated mkdirp to fix [CVE-2020-7598](https://nvd.nist.gov/vuln/detail/CVE-2020-7598)
- Fix a security issue: updated acorn to fix [CVE-2020-7598](https://nvd.nist.gov/vuln/detail/CVE-2020-7598)
- Fix a security issue: updated actionview to fix [CVE-2020-5267](https://nvd.nist.gov/vuln/detail/CVE-2020-5267)
- [TODO DEPLOY] `rails fablab:fix:avoirs_wallet_transaction`
- [TODO DEPLOY] `rails fablab:es:generate_stats[289]` only if you had missing statistics since some date ago (here 289 days)

## v4.3.2 2020 March 11

- Secure the session cookie
- Improved contextual help with a modal dialog
- Updated translations
- Refactored translations to help merging Crowdin PR
- Updated translation documentation
- Fix a bug: unable to create new availabilities if SLOT_DURATION is not defined

## v4.3.1 2020 March 04

- Updated user's manual for v4.3 (fr)
- Display user's manual when asking for help, if no tour is available
- Change style and pluralize the text of the slot division alert in new availability assistant
- Fix a bug: in feature tours, next and previous arrows may be broken on some systems
- Fix a bug: in the user's menu, two links to the personal wallet
- Fix a bug: spaces item is not at the correct position in the admin navigation menu

## v4.3.0 2020 March 04

- Ability to configure reservation slot restricted for plan subscribers
- Ability to configure the policy (allow or prevent) for members booking a machine/formation/event slot, if they already have a reservation the same day at the same time
- Ability to create and delete periodic calendar availabilities (recurrence)
- Ability to fully customize the home page
- Automated setup assistant
- An administrator can delete a member
- An event reservation can be cancelled, if reservation cancellation is enabled
- Delete multiple recurring events at one time
- Edit multiple recurring events at one time
- Ability to import iCalendar agendas in the public calendar, through URLs to ICS files (RFC 5545)
- Ability to configure the duration of a reservation slot, using `SLOT_DURATION`. Previously, only 60 minutes slots were allowed
- Ability to force the email validation when a new user registers. This is optionally configured with `USER_CONFIRMATION_NEEDED_TO_SIGN_IN`
- Display the scheduled events in the admin calendar, depending on `EVENTS_IN_CALENDAR` configuration.
- Display indications on required fields in new administrator form
- Administrators can to book machine/space/training slots, until 1 month in the past
- Filter members by non-validated emails or by inactive for 3 years
- Ability to customize the title of the link to the about page
- Feature tours for administrators that provides contextual help
- Automatic version check with security alerts
- Public endpoint to check the system health
- Configuration of phone number in members registration forms: can be required or optional, depending on `PHONE_REQUIRED` configuration
- Improved user experience in defining slots in the calendar management
- Improved notification email to the member when a rolling subscription is taken
- Notify all admins on the creation of a refund invoice
- Helper links between admin sections of the scheduling process
- Calendar management: improved legend display and visual behavior
- Reorganized left menu
- Create machine availabilities: select all/none in a click
- Prevent event reservation in the past [Taiga#127]
- Removed the need of twitter API keys to display the last tweet on the home page
- Various helper links to help newcomers creating their first items
- Handle Ctrl^C in upgrade scripts
- Updated moment-timezone
- Updated angular-ui-bootstrap from v0.14 to v1.2
- Updated caxlsx to 3.0.1 and rails_axlsx to rails_caxlsx
- Updated sidekiq to 5.2.8
- Option to disable developers analytics
- Added the a "cron" tab in Sidekiq web-ui to watch scheduled tasks
- Integration of Crowdin "in-context" translation management system
- Added freeCAD files as default allowed extensions
- Rake task to sync local users with Stripe
- Unified translations syntax to use ICU MessageFormat
- Refactored front-end translations keys with unified paths
- Updated and refactored README and documentations
- Harmonized Fab-manager typography and case
- Updated seeds file
- Fix a bug: unable to remove the picture from a training
- Fix a bug: no alerts on errors during admin creation
- Fix a bug: replaces all Time.now by DateTime.current to prevent time zones issues [Taiga#134]
- Fix a bug: logs are not printed in staging environment
- Fix a bug: theme colors must be selected twice before the changes became effective
- Fix a bug: datepicker does not work in profile completion screen
- Fix a bug: unable to select a group in profile completion screen
- Fix a bug: in some cases, bogus admin notification on profile completed
- Fix a bug: with Firefox browser, the texts in date inputs are shifted to the bottom
- Fix a bug: sometimes when browsing the invoices section, the translations are missing
- Fix a bug: first day of week is ignored in agendas (#169)
- Fix a bug: statistics page is bogus before the creation of the first plan
- Fix a bug: default invoice logo is broken and prevent invoice generation
- Fix a security issue: updated loofah to fix [CVE-2019-15587](https://nvd.nist.gov/vuln/detail/CVE-2019-15587)
- Fix a security issue: updated angular to 1.7.9 to fix [CVE-2019-10768](https://nvd.nist.gov/vuln/detail/CVE-2019-10768)
- Fix a security issue: updated puma to 3.12.4 to fix [GHSA-7xx3-m584-x994](https://github.com/advisories/GHSA-7xx3-m584-x994), [CVE-2020-5247](https://nvd.nist.gov/vuln/detail/CVE-2020-5247) and [CVE-2019-16254](https://nvd.nist.gov/vuln/detail/CVE-2020-5247)
- Fix a security issue: updated nokogiri to 1.10.8 to fix [CVE-2020-7595](https://nvd.nist.gov/vuln/detail/CVE-2020-7595)
- Fix a security issue: updated rack to 1.6.12 to fix [CVE-2019-16782](https://nvd.nist.gov/vuln/detail/CVE-2019-16782)
- [TODO DEPLOY] add the `SLOT_DURATION` environment variable (see [doc/environment.md](doc/environment.md#SLOT_DURATION) for configuration details)
- [TODO DEPLOY] add the `PHONE_REQUIRED` environment variable (see [doc/environment.md](doc/environment.md#PHONE_REQUIRED) for configuration details)
- [TODO DEPLOY] add the `EVENTS_IN_CALENDAR` environment variable (see [doc/environment.md](doc/environment.md#EVENTS_IN_CALENDAR) for configuration details)
- [TODO DEPLOY] add the `USER_CONFIRMATION_NEEDED_TO_SIGN_IN` environment variable (see [doc/environment.md](doc/environment.md#USER_CONFIRMATION_NEEDED_TO_SIGN_IN) for configuration details)
- [TODO DEPLOY] add the `BOOK_SLOT_AT_SAME_TIME` environment variable (see [doc/environment.md](doc/environment.md#BOOK_SLOT_AT_SAME_TIME) for configuration details)
- [TODO DEPLOY] -> (only dev) `bundle install && yarn install`
- [TODO DEPLOY] `rake db:migrate && rake db:seed`
- [TODO DEPLOY] `rake fablab:fix:name_stylesheet`

## v4.2.4 2019 October 30

- Fix a bug: in some cases, the invoices were not generated after deploying v4.2.0+. This can occurs if VAT was changed/enabled during the application life (#156)
- [TODO DEPLOY] `rake fablab:maintenance:regenerate_invoices[2019,10]` only if you had download issues with your last invoices

## v4.2.3 2019 October 22

- Ability to set the default view in project gallery: openLab or local
- Fix a bug: admins can't edit members projects
- [TODO DEPLOY] add the `OPENLAB_DEFAULT` environment variable (see [doc/environment.md](doc/environment.md#OPENLAB_DEFAULT) for configuration details)

## v4.2.2 2019 October 22

- Fix a bug: PostgreSQL upgrade script won't run on some systems

## v4.2.1 2019 October 21

- Updated axlsx gem to caxlsx 3.0
- Updated axlsx_rails to 0.6.0
- Fix a security issue: updated rubyzip to 1.3.0 to fix [CVE-2019-16892](https://nvd.nist.gov/vuln/detail/CVE-2019-16892)

## v4.2.0 2019 October 21

- Upgraded PostgreSQL from 9.4 to 9.6
- Optional reCaptcha checkbox in sign-up form
- Ability to configure and export the accounting data to the ACD accounting software
- Compute the VAT per item in each invoices, instead of globally
- Use Alpine Linux to build the Docker image (#147)
- Updated omniauth & omniauth-oauth2 gems
- Ability to set project's CAO attachement maximum upload size
- Ability to bulk-import members from a CSV file
- Ability to disable invoices generation and interfaces
- Added a known issue to the README (#152)
- Ability to fully rebuild the projets index in ElasticSearch with `rake fablab:es:build_projects_index`
- Ability to configure SMTP connection to use SMTP/TLS
- Updated user's manual for v4.2 (fr)
- Fix a bug: invoices with total = 0, are marked as paid on site even if paid by card
- Fix a bug: after disabling a group, its associated plans are hidden from the interface
- Fix a bug: in case of unexpected server error during stripe payment process, the confirm button is not unlocked
- Fix a bug: create a plan does not set its name
- Fix a bug: unable to dissociate the last machine from a formation
- Fix a bug: in profile_complete form, the user's group is not selected by default
- Fix a bug: missing asterisks on some required fields in profile_complete form
- Fix a bug: public calendar won't show anything if the current date range include a reserved space availability (#151)
- Fix a bug: invoices list is not shown by default in "manage invoices" section
- Fix a bug: unable to run rake `fablab:es:*` tasks due to an issue with gem faraday 0.16.x (was updated to 0.17)
- Fix a bug: unauthorized user can see the edit project form
- Fix a bug: do not display each days in invoices for multiple days event reservation
- Fix a security issue: fixed [CVE-2015-9284](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9284)
- [TODO DEPLOY] -> (only dev) `yarn install` and `bundle install`
- [TODO DEPLOY] -> (only dev) configure `DEFAULT_HOST: 'localhost:5000'` and `DEFAULT_PROTOCOL: http` in [application.yml](config/application.yml.default)
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] add `- ${PWD}/imports:/usr/src/app/imports` in the volumes list of your fabmanager service in [docker-compose.yml](docker/docker-compose.yml)
- [TODO DEPLOY] add the `RECAPTCHA_SITE_KEY` and `RECAPTCHA_SECRET_KEY` environment variables (see [doc/environment.md](doc/environment.md#RECAPTCHA_SITE_KEY) for configuration details)
- [TODO DEPLOY] add the `MAX_CAO_SIZE` environment variable (see [doc/environment.md](doc/environment.md#MAX_CAO_SIZE) for configuration details)
- [TODO DEPLOY] add the `MAX_IMPORT_SIZE` environment variable (see [doc/environment.md](doc/environment.md#MAX_IMPORT_SIZE) for configuration details)
- [TODO DEPLOY] add the `FABLAB_WITHOUT_INVOICES` environment variable (see [doc/environment.md](doc/environment.md#FABLAB_WITHOUT_INVOICES) for configuration details)
- [TODO DEPLOY] add the `SMTP_TLS` environment variable (see [doc/environment.md](doc/environment.md#SMTP_TLS) for configuration details)
- [TODO DEPLOY] add the `FABLAB_WITHOUT_WALLET` environment variable (see [doc/environment.md](doc/environment.md#FABLAB_WITHOUT_WALLET) for configuration details)
- [TODO DEPLOY] **IMPORTANT** Please read [postgres_upgrade.md](doc/postgres_upgrade.md) for instructions on upgrading PostgreSQL.

## v4.1.1 2019 September 20

- Fix a bug: api/reservations#index was using user_id instead of statistic_profile_id
- Fix a bug: event_service#date_range method, test on all_day was never truthy
- Fix a bug: sidekiq 5 does not have delay_for method anymore, uses perform_in instead

## v4.1.0 2019 September 12

- Handling the Strong-Customer Authentication (SCA) for online payments
- Ability to disable online payments though an environment variable
- Log changes in Invoices or InvoiceItems records for better handling of accounting certification issues
- Updated virtual development environment (#142)
- Upgrade dev environments from ruby 2.3.6 to 2.3.8 (#143)
- Upgraded the stripe API from 2015-10-16 to 2019-08-14
- Upgraded stripe-js from v2 to v3
- Fix a bug: Users with role 'member' cannot download their invoices
- Fix a bug: Wallet credit inputs does not allow to put zeros at the end of the decimal part of the amount
- Fix a bug: unable to create the first user because role member was missing
- Fix a bug: disabled groups still appears as available in sign-up modal
- Fix a bug: extend a current subscription for a member, does not reset his credits (#145)
- Fix a bug: once a reservation was made, the reminder of the paid price is always 0 if a coupon was used
- Fix a security issue: updated nokogiri to 1.10.4 to fix [CVE-2019-5477](https://nvd.nist.gov/vuln/detail/CVE-2019-5477)
- Fix a security issue: updated eslint-utils to 1.4.2 to fix [GHSA-3gx7-xhv7-5mx3](https://github.com/mysticatea/eslint-utils/security/advisories/GHSA-3gx7-xhv7-5mx3)
- Fix a security issue: updated devise to 4.7.1 to fix [CVE-2019-16109](https://nvd.nist.gov/vuln/detail/CVE-2019-16109)
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] add the `FABLAB_WITHOUT_ONLINE_PAYMENT` environment variable (see [doc/environment.md](doc/environment.md) for configuration details)
- [TODO DEPLOY] -> (only dev) `rvm install ruby-2.3.8 && rvm use && bundle install`

## v4.0.4 2019 August 14

- Fix a bug: #140 VAT rate is erroneous in invoices.
  Note: this bug was introduced in v4.0.3 and requires (if you are on v4.0.3) to regenerate the invoices since August 1st
- [TODO DEPLOY] `rake fablab:maintenance:regenerate_invoices[2019,8]`

## v4.0.3 2019 August 01

- Fix a bug: no user can be created after the last member was deleted
- Fix a bug: unable to generate a refund (Avoir)
- Fix a bug: a newly generated refund is displayed as broken (unchained record) even if it is correctly chained
- Fix a bug: when regenerating invoices PDF, VAT history is ignored
- Fix a security issue: updated lodash to 4.17.14 to fix [CVE-2019-10744](https://github.com/lodash/lodash/pull/4336)
- Fix a security issue: updated mini_magick to 4.9.4 to fix [CVE-2019-13574](https://nvd.nist.gov/vuln/detail/CVE-2019-13574)
- Fix some security issues: updated bootstrap to 3.4.1 to fix [CVE-2019-8331](https://nvd.nist.gov/vuln/detail/CVE-2019-8331), [CVE-2019-14041](https://nvd.nist.gov/vuln/detail/CVE-2018-14041), and 3 other low severity CVE
- Fix some security issues: updated sidekiq to 5.2.7 to fix XSS and CRSF issues
- Removed dependency to jQuery UI
- Updated angular-xeditable, to remove dependency to jquery 1.11.1
- [TODO DEPLOY] -> (only dev) `bundle install`

## v4.0.2 2019 July 10

- Fix a bug: unable to export members list
- Fix a bug: unable to export reservations or subscriptions to excel
- Fix a bug: projects RSS feed fails to render
- Fix a bug: abuses reports are not notified to admins
- Fix a bug: SubscriptionExpireWorker cannot run due to wrong expiration column in SQL query
- Fix a bug: OpenlabWorker is crashing with message undefined method `profile' for StatisticProfile
- Prevent invalid invoice logo from crashing the InvoiceWorker
- Updated user's manual for v4 (fr)
- Optimized Dockerfile to speed up build time

## v4.0.1 2019 June 17

- Fix a bug: migration 20190523140823 may not run if an admin was deleted
- Fix a bug: cookie consent modal is not shown
- Fix a bug: prevent task migrate_pdf_invoices_folders from raising an error when run with no invoices
- Documentation about dumping the database

## v4.0.0 2019 June 17

- Configurable privacy policy and data protection officer
- Alert users on privacy policy update
- Abuses reports management panel
- Refactored user's profile to keep invoicing data after an user was deleted
- Refactored user's profile to keep statistical data after an user was deleted
- Ability to delete an user (fixes #129 and #120)
- Ask user acceptance before deposing analytics cookies
- Fix a bug: (spanish) some translations are not loaded correctly
- Fix a bug: some users may not appear in the admin's general listing
- Fix a bug: Availabilities export report an erroneous number of reservations for machine availabilities (#131)
- Fix a bug: close period reminder is sent before the first invoice's first anniversary
- Fix a bug: Canceled reservations are not removed from statistics (#133)
- Improved translations syntax according to YML specifications
- Refactored some Ruby code to match style guide
- [TODO DEPLOY] `rake fablab:fix:users_group_ids`
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] `rake db:seed`
- [TODO DEPLOY] `rake fablab:setup:migrate_pdf_invoices_folders`
- [TODO DEPLOY] `rake fablab:maintenance:delete_inactive_users` (will prompt for confirmation)
- [TODO DEPLOY] `rake fablab:maintenance:rebuild_stylesheet`

## v3.1.2 2019 May 27

- Fix a bug: when generating an Avoir at a previous date, the resulting checksum may be invalid
- Fix a bug: updating a setting does not chain new values
- Fix a security issue: updated to jquery 3.4.1 to fix [CVE-2019-11358](https://nvd.nist.gov/vuln/detail/CVE-2019-11358)
- [TODO DEPLOY] `rake fablab:setup:chain_invoices_items_records`
- [TODO DEPLOY] `rake fablab:setup:chain_invoices_records`
- [TODO DEPLOY] `rake fablab:setup:chain_history_values_records`
- [TODO DEPLOY] -> (only dev) yarn install

## v3.1.1 2019 April 8

- Fix a bug: when paying a reservation with wallet, the invoice footprint is not correctly updated

## v3.1.0 2019 April 8

- Asynchronously generate accounting archives
- Improved end-user message when closing an accounting period
- Improved date checks before closing an accounting period
- Paginate list of coupons
- Allow filtering coupons list
- Fix a bug: when VAT has changed during Fab-manager's lifecycle, this may not be reflected in archives
- Fix a bug: using a quote in event category's name results in angular $parse:syntax Error

## v3.0.1 2019 April 1st

- Insert archive generation datetime in chained.sha256
- Updated documentation and diagrams

## v3.0.0 2019 March 28

- (France) Compliance with Article 88 of Law No. 2015-1785 and BOI-TVA-DECLA-30-10-30-20160803 : Certification of cash systems
- Ability for an admin to view and close accounting periods
- Secured archives for closed accounting periods
- Securely chained invoices records with visual control of data integrity
- Notify an user if the available disk space reaches a configured threshold
- Invoices generated outside of production environment will be watermarked
- Keep track of currently logged user on each generated invoice
- Fix a bug: unable to add a file attachment to an event
- Fix a security issue: updated to devise 4.6.0 to fix [CVE-2019-5421](https://github.com/plataformatec/devise/issues/4981)
- Fix a security issue: updated Rails to 4.2.11.1 to fix [CVE-2019-5418](https://groups.google.com/forum/#!topic/rubyonrails-security/pFRKI96Sm8Q) and [CVE-2019-5419](https://groups.google.com/forum/#!topic/rubyonrails-security/GN7w9fFAQeI)
- Removed deprecated Capistrano deployment system
- Rebranded product from "La Casemate"
- Refactored some pieces of Ruby code, according to style guide
- Added asterisks on required fields in sign-up form
- [TODO DEPLOY] /!\ Before deploying, you must check (and eventually) correct your VAT history using the rails console. Missing rates can be added later but dates and rates (including date of activation, disabling) MUST be correct. These values are very likely wrong if your installation was made prior to 2.8.0 with VAT enabled. Other cases must be checked too.
- [TODO DEPLOY] -> (only dev) if applicable, you must first downgrade bundler to v1 `gem uninstall bundler --version=2.0.1 && gem install bundler --version=1.7.3 && bundle install`
- [TODO DEPLOY] if you have changed your VAT rate in the past, add its history into database. You can use a rate of "0" to disable VAT. Eg. `rake fablab:setup:add_vat_rate[20,2017-01-01]`
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] `rake fablab:setup:set_environment_to_invoices`
- [TODO DEPLOY] `rake fablab:setup:chain_invoices_items_records`
- [TODO DEPLOY] `rake fablab:setup:chain_invoices_records`
- [TODO DEPLOY] `rake fablab:setup:chain_history_values_records`
- [TODO DEPLOY] add `DISK_SPACE_MB_ALERT` and `SUPERADMIN_EMAIL` environment variables (see [doc/environment.md](doc/environment.md) for configuration details)
- [TODO DEPLOY] add the `accounting` volume to the Fab-manager's image in [docker-compose.yml](docker/docker-compose.yml)

## v2.8.4 2019 March 18

- Limit members search to 50 results to speed up queries
- Refactored rake tasks to use namespaces and descriptions
- Fix a bug: unable to create a new oAuth 2.0 provider
- Fix a bug: application in unavailable if a SSO is active
- Fix a security issue: dependency bootstrap < 4.3.1 has an XSS vulnerability as described in [CVE-2019-8331](https://blog.getbootstrap.com/2019/02/13/bootstrap-4-3-1-and-3-4-1/)
- Fixed missing translations in authentication providers form
- [TODO DEPLOY] -> (only dev) `bundle install`

## v2.8.3 2019 January 29

- Added user's manual (fr)
- Fix a bug: unable to run rails console
- Fix a bug: some reservation slots are not shown on the user calendars (#127)

## v2.8.2 2019 January 22

- Removed ability to disable invoicing for an user
- Improved user autocompletion when using multiple words
- Refactored API controllers
- Fixed a missing translation in plan form
- Fix a bug: error handling on password recovery
- Fix a bug: error handling on machine attachment upload
- Fix a bug: first day of week is ignored in statistics custom filter
- Fix a bug: rails DSB locale is invalid
- Fix a bug: unable to delete an admin who has changed a setting
- Fix a bug: unable to create/edit a plan of 12 months or 52 weeks
- Fix a bug: Unable to search in user autocomplete fields
- Fix a bug: Invalid translation in new partner modal
- Refactored frontend invoices translations
- Updated RailRoady 1.4.0 to 1.5.3
- [TODO DEPLOY] -> (only dev) `bundle install`

## v2.8.1 2019 January 02

- Fix ES upgrade: when docker-compose file is using ${PWD}, the ES config volume is attached to the wrong container
- Fixed environment documentation references for external locales
- Fixed missing translations (EN & ES) and improved others (ES)
- Fix a bug: unable to fetch projects from OpenProjects (#126)
- Fix a bug: unable to create or edit a plan

## v2.8.0 2018 December 27

- Refactored subscriptions to keep track of the previous ones
- Refactored settings to keep track of the previous values (notably VAT rate)
- Improved automated tests suite
- Added Rubocop gem to the Gemfile (ruby syntax checking)
- Added badges to README
- Fix a security issue: dependency ActiveJob < 4.2.11 has a vulnerability as described in [CVE-2018-16476](https://nvd.nist.gov/vuln/detail/CVE-2018-16476)
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] -> (only dev) `bundle install`

## v2.7.4 2018 December 04

- Applied Rubocop rules to some ruby files
- Prevent running elastic-upgrade script with wrong awk version
- Fix ElasticSearch upgrade script
- Setup ElasticSearch configuration files for new installations
- Improved ES upgrade documentation

## v2.7.3 2018 December 03

- Updated Uglifier gem to support ES6 syntax
- Fix rake task `fablab:es:build_projects_index` for ElasticSearch > 1.7
- Fix Dockerfile: yarn was not setup correctly
- Fix: unable to build assets

## v2.7.2 2018 November 29

- Allow running the ElasticSearch upgrade script while being root
- Fix an issue with ES upgrade script, preventing reindexing in some cases
- Improved ES upgrade documentation

## v2.7.1 2018 November 27

- Updated angular.js to 1.6
- Fix a security issue: dependency jQuery < 3.0.0 has a vulnerability as described in [CVE-2015-9251](https://nvd.nist.gov/vuln/detail/CVE-2015-9251)
- Fix a security issue: dependency moment < 2.11.2 has a vulnerability as described in [CVE-2016-4055](https://nvd.nist.gov/vuln/detail/CVE-2016-4055)
- Fix a security issue: dependency moment < 2.19.3 has a vulnerability as described in [CVE-2017-18214](https://nvd.nist.gov/vuln/detail/CVE-2017-18214)
- Fix a security issue: dependency RubyZip < 1.1.2 has a vulnerability as described in [CVE-2018-1000544](https://nvd.nist.gov/vuln/detail/CVE-2018-1000544)
- Fix a security issue: dependency ffi < 1.9.24 has a vulnerability as described in [CVE-2018-1000201](https://nvd.nist.gov/vuln/detail/CVE-2018-1000201)

## v2.7.0 2018 November 27

- Nom using standard [package.json](package.json) file to save application version number
- Now using Yarn instead of deprecated Bower as the front-end dependencies manager
- Migrated front-end application from CoffeeScript to ECMAScript 6 (JS)
- Integration of Eslint and Rubocop coding rules
- Fix a bug: on small screens, display of button "change group" overflows
- Fix a bug: creating a transverse plan, create one for the hidden admins group
- Fix a bug: on some classical docker installations, the elastic-upgrade.sh script won't run successfully
- Fix a security issue: dependency rack has a vulnerability as described in [CVE-2018-16471](https://nvd.nist.gov/vuln/detail/CVE-2018-16471)
- Fix a security issue: dependency loofah has a vulnerability as described in [CVE-2018-16468](https://github.com/flavorjones/loofah/issues/154)
- Updated documentation

## v2.6.7 2018 October 4

- Ability to configure SMTP more precisely
- Typo correction in README (#121)
- [TODO DEPLOY] add the following environment variables: `SMTP_AUTHENTICATION, SMTP_ENABLE_STARTTLS_AUTO, SMTP_OPENSSL_VERIFY_MODE`

## v2.6.6 2018 September 18

- Ability to parametrize machines order on the booking page
- Ability to set a neutral gender for the fablab's title (#108)
- Fix a bug: rake task `fablab:fix:categories_slugs` bash interpretation error
- Fix a bug: file inputs filled with long filenames render improperly with an overflow
- Fix a bug: title concordance radio buttons render improperly on smaller screens
- Improved verifications in ElasticSearch upgrade script
- [TODO DEPLOY] `rake fablab:fix:categories_slugs`
- [TODO DEPLOY] `rake db:seed`

## v2.6.5 2018 July 24

- Upgraded ElasticSearch from 1.7 to 5.6
- Ability to display the name of the user who booked a machine slot to other members
- Updated OmniAuth to fix Hashie warnings [omniauth#872](https://github.com/omniauth/omniauth/issues/872)
- Fix a bug: unable to filter statistics from age 0
- Fix a bug: events categories are not reported correctly in statistics
- Fix a security issue: dependency loofah has a vulnerability as described in [CVE-2018-8048](https://github.com/flavorjones/loofah/issues/144)
- Fix a security issue: rails-html-sanitizer < 1.0.3 has a security vulnerability described in [CVE-2018-3741](https://nvd.nist.gov/vuln/detail/CVE-2018-3741)
- Fix a security issue: nokogiri < 1.8.2 has a security vulnerability as described in [CVE-2017-18258](https://nvd.nist.gov/vuln/detail/CVE-2017-18258)
- Fix a security issue: sprockets < 2.12.5 has a security vulnerability as described in [CVE-2018-3760](https://nvd.nist.gov/vuln/detail/CVE-2018-3760)
- Ensure elasticSearch indices are started with green status on new installations
- Refactored User.to_json to remove code duplication
- Fixed syntax and typos in README
- [TODO DEPLOY] **IMPORTANT** Please read [elastic_upgrade.md](doc/elastic_upgrade.md) for instructions on upgrading ElasticSearch.
- [TODO DEPLOY] `rake fablab:fix:categories_slugs`
- [TODO DEPLOY] -> (only dev) `bundle install`
- [TODO DEPLOY] `rake db:seed`

## v2.6.4 2018 March 15

- Ability to share trainings on social medias
- Fix a bug: a reminder notification were sent for canceled reservations
- Fix a bug: sharing an event on facebook has HTML tags in the description
- Set Stripe API version, all Fab-managers has to use this version because codebase relies on it
- Fix a security issue: OmniAuth < 1.3.2  has a security vulnerability described in [CVE-2017-18076](https://nvd.nist.gov/vuln/detail/CVE-2017-18076)
- Fix a security issue: rack-protection < 1.5.5 has a security vulnerability described in [CVE-2018-1000119](https://nvd.nist.gov/vuln/detail/CVE-2018-1000119)
- Fix a security issue: http gem < 0.7.3 has a security vulnerability described in [CVE-2015-1828](https://nvd.nist.gov/vuln/detail/CVE-2015-1828), updates twitter gem as a dependency

## v2.6.3 2018 January 2

- Fix a bug: wrong docker-compose url in setup script (#98)
- Typo correction in docker README (#97)

## v2.6.2 2017 December 21

- Support for internet explorer 11
- Fix a bug: events order in public list
- Fix a bug: unable to create a training credit
- Corrected typos in documentation (#96)
- Improved test suite coverage

## v2.6.1 2017 December 14

- Updated Portuguese translations (#91)
- Added Spanish translations (#87)
- Added Central Africa & Cameroon currency symbol (#90)
- Fix nginx configuration to allow initial Let's Encrypt configuration (#92)
- Events: open api and monitor improvement (#79)
- Fix a bug: refund an invoice with a subscription and disabling it a the same time cause the resulting PDF to display the wrong dates
- Fix a bug: unable to successfully run the test suite after wednesday
- Fix a security issue: in development environments, web-console has a vulnerability as described in CVE-2015-3224
- Fixed deploy instructions with docker-compose
- Updated docker installation instructions

## v2.6.0 2017 November 13

- Additional button to delete a slot, allowing to delete slots masked by others
- Removed cross hack in full-calendar
- Confirmation before slot delete
- Confirmation and error handling while deleting an event
- Ability to disable groups, machines, plans, spaces and trainings
- Improved responsiveness of machines and spaces lists
- Allow setting of decimal prices
- Fix a typo: error message while creating a machine slot
- Fix a bug: events pagination is bogus in admin's monitoring when selecting non default filter
- Fix a bug: social sharing failed for projects with an underscore in their name
- Fix a bug: html tags of events description not stripped when sharing on social network
- Fix a bug: event, space, training or machine main image on description page is deformed on small devices
- Fix a bug: profile completion of non-SSO imported users trigger a fuzzy email
- Fix a bug: creation of negative credits
- Fix a bug: unable to display profiles of users whom any reservation is associated with a deleted object
- Updated test data to allow passing test suite
- Upgraded rails minor version
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] -> (only dev) `bundle install`

## v2.5.14 2017 September 12

- Fix a bug: Error message in fix:recursive_events_over_DST failed and does not report events to check

## v2.5.13 2017 September 11

- Fix a bug: ActiveRecord::RecordNotFound when running rake task fix:recursive_events_over_DST with recursive events which the initial event was deleted

## v2.5.12 2017 September 11

- Fix a bug: Long words overflow from homepage's events blocks
- Fix a bug: ActiveRecord::RecordNotFound when running rake task fix:recursive_events_over_DST with non-recursive events

## v2.5.11 2017 September 7

- Added tooltip concerning images insertion while configuring the about page
- Ability for admins to configure the maximum visibility for availabilities reservation
- Administrators isolation in a special group
- In login modal, displays an alert if Caps lock key is pressed
- Prevent creation of irregular yearly plans (eg. 12 months)
- Ability to lock machine, space or training availability slots, to prevent new reservations on them
- Fix a bug: admins cannot see all availabilities for spaces in reservation calendar when a user is selected
- Fix a bug: missing translation after payment in english and portuguese
- Fix a bug: invalid notification when sending monetary coupon to users
- Fix a bug: unable to delete group "standard"
- Fix a bug: recursive events crossing Daylight Saving Time period changes are shifted by 1 hour
- Fix a bug: unable to see availabilities in the public calendar when browsing as a visitor (non-connected)
- Updated puma for compatibility with openSSL > 1.0
- Documented installation on ArchLinux
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] `rake db:seed` then `rake fablab:fix:migrate_admins_group`
- [TODO DEPLOY] `rake fablab:fix:recursive_events_over_DST`

## v2.5.10 2017 August 16

- Updated axlsx gem for excel files generation, possible fix for #489
- Fix a bug: on some linux hosts, a filename too long error is triggered when accessing the following API: trainings, groups, events, prices
- update docker/README.md

## v2.5.9 2017 July 13

- Fixed invalid syntax for configuration file application.yml.default
- db:seed improves test if there is already an admin, not failing anymore if role 'admin' doesn't exist

## v2.5.8 2017 July 12

- Fix a bug: when upgrading from version < 2.5.0, `db:seed` will throw an error if ADMIN_EMAIL does not match any admin in database
- Fix a bug: hide spaces in public calendar when module is disabled
- Fix a bug: confirmation message not shown after admin creation
- Fix a bug: invoices generation failed for subscription days offered
- add task `rake fablab:get_incoherent_invoice` allow find the invoices incoherent

## v2.5.7 2017 June 8

- Portuguese and Brazilian support
- Fix a bug: reservation amount total isnt equal stripe invoice amount that be paid by customer

## v2.5.6 2017 May 18

- Ability for admins to create users as organizations
- Invoices object will contain the organization name if any (#64)
- RSS feeds will return more data about events and projects, especially images
- Improved Docker documentation (#65)

## v2.5.5 2017 May 15

- Fix a bug: New groups does not have their spaces prices initialized
- Fix a bug: Unable to delete a group when its space prices are set
- [TODO DEPLOY] `rake fablab:fix:new_group_space_prices` only if module 'Spaces' is/was enabled

## v2.5.4 2017 May 4

- Fix a bug: Unable to define application locale other than `fr` or `en`.
- [TODO DEPLOY] add `APP_LOCALE` environment variable (see README.md for configuration details)

## v2.5.3 2017 April 27

- Project view: added responsive support on external images
- Include rails localization support for 115 new locations

## v2.5.2 2017 April 12

- Extracts first admin created email and password into environment variables
- [OPTIONAL: Only for a new installation] add `ADMIN_EMAIL` and  `ADMIN_PASSWORD` environment variable in `application.yml` or `env` file (with docker)

## v2.5.1 2017 March 28

- hide spaces in admin's credit management if spaces are disabled
- Fix a bug: Can not display training tracking (this bug was introduced in version 2.5.0)
- [TODO DEPLOY] `rake assets:precompile`

## v2.5.0 2017 March 28

- Ability to remove an unused custom price for an event (#61)
- Prevent polling notifications when the application is in background
- Ability to export the availabilities and their reservation rate from the admin calendar
- Ability to create, manage and reserve spaces
- Improved admin's interface to create availabilities
- Complete rewrote of the reservation cart functionality with improved stability, performance and sustainability
- Replaced letter_opener by MailCatcher to preview e-mails in development environments
- Ability to create plans with durations based on weeks
- Ease installations with docker-compose, in any directory (#63)
- Fix a bug: trainings reservations are not shown in the admin's calendar
- Fix a bug: unable to delete an administrator from the system
- Fix a bug: unable to delete an event with a linked custom price (#61)
- Fix a bug: navigation in client calendar is bogus when browsing months (#59)
- Fix a bug: subscription name is not shown in invoices
- Fix a bug: new plans statistics are not shown
- [TODO DEPLOY] `rake db:migrate`, then `rake db:seed`
- [TODO DEPLOY] add the `FABLAB_WITHOUT_SPACES` environment variable
- [TODO DEPLOY] `rake fablab:es:add_spaces`
- [TODO DEPLOY] `rake fablab:fix:new_plans_statistics` if you have created plans from v2.4.10

## v2.4.11 2017 March 15

- Fix a bug: editing and saving a plan, result in removing the rolling attribute
- [TODO DEPLOY] `rake fablab:fix:rolling_plans`

## v2.4.10 2017 January 9

- Optimized notifications system
- Fix a bug: when many users with too many unread notifications are connected at the same time, the system kill the application due to memory overflow
- Fix a bug: ReservationReminderWorker crash with undefined method find_by
- Fix a bug: navigation to about page duplicates admin's links in left menu
- Fix a bug: changing the price of a plan lost its past statistics
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] `rake fablab:fix:set_plans_slugs`

## v2.4.9 2017 January 4

- Mask new notifications alerts when more than 3
- Added an asterisk on group select in admin's member form
- Statistics custom aggregations can handle custom filtering
- Statistics about hours available for machine reservations and tickets available for training reservations, now handle custom filtering on date and type
- Fix a bug: display more than 15 unread notifications (number on the bell icon & full list)
- Fix a bug: in invoice configuration panel, VAT amount and total excl. taxes are inverted
- Fix a bug: unable to compute user's age when they were born on february 29th and current year is not a leap year
- Fix a bug: wrong statistics about hours available for machines reservation. Fix requires user action (1)
- Fix a bug: when regenerating statistics, previous values are not fully removed (only 10 firsts), resulting in wrong statistics generation (2)
- Fix a bug: when deleting an availability just after its creation, the indexer workers crash and retries for a month
- [TODO DEPLOY] remove possible value `application/` in `ALLOWED_MIME_TYPES` list, in environment variable
- [TODO DEPLOY] `rails runner StatisticCustomAggregation.destroy_all`, then `rake db:seed`, then `rake fablab:es:build_availabilities_index` (1)
- [TODO DEPLOY] `rake fablab:es:generate_stats[1095]` if you already had regenerated the statistics in the past, then they are very likely corrupted. Run this task to fix (2)

## v2.4.8 2016 December 15

- Added asterisks on mandatory fields in member's form
- Fixed wording on SSO screens
- Ability to send again the auth-system migration token by email
- Fix a bug: notification email about refund invoice tells about subscription while concerning wallet credit

## v2.4.7 2016 December 14

- Improved automated testing
- Added an information notice about the processing time of deleting an administrator
- Ability to change the expiration date of a coupon after its creation
- Ability to generate a refund invoice when crediting user's wallet
- Fix a bug: unable to run rake db:migrate on first install
- Fix a bug: unable to create or edit a coupon of type 'percentage'

## v2.4.6 2016 November 30

- Change display of message about coupon application status
- Fix a bug: compute price API return error 500 if reservable_id is not provided

## v2.4.5 2016 November 29

- Ability to create coupons with cash amounts (previously only percentages were allowed)
- Improved error messages when something wrong append when paying a machine reservation by stripe
- Ability to display optional information message on event reservation page
- Fix a bug: misconfigured Twitter's ENV variables results in HTTP error 500
- Fix a bug: wallet is not debited when paying locally with a user who have invoices disabled
- Fix a bug: wrong error message about rounding inconsistency is logged on invoice generation
- Fix a bug: reservation calendar of a specific training shows availabilities for all trainings
- [TODO DEPLOY] `rake db:migrate`

## v2.4.4 2016 November 24

- Fix a bug: unable to rollback migration 20160906145713
- Fix a bug: Title's translation for plan's forms is not loaded in French
- Fix a bug: invoice of reservation show payment by debit card when user pay with wallet

## v2.4.3 2016 November 21

- Export user's invoicing status in members' excel export
- Fix a bug: Next events descriptions, shown on the home page, display raw html
- Fix a bug: number of reserved seats for an event is always of 1 in the excel export of reservations
- Fix a bug: conflict between similar translations around "reservations"
- Fix a bug: later occurrences of recurrent events does not have the initially configured theme and age range
- Fix a bug: some graphs do not display: events, users, trainings and machine hours
- [TODO DEPLOY] delete the `exports/users/reservations` folder to prevent the usage of old invalid exports

## v2.4.2 2016 November 8

- Image max size is configurable, default size is 2 megabytes
- Allow add more pictures for project step
- Ability to use HTML in event's descriptions using a WYSIWYG editor
- Fix a bug: statistics graphs were not showing
- Fix a bug: On invoices, only starting date is shown for multi-days events
- Fix a bug: In the sign-up modal, the translation for 'i_accept_to_receive_information_from_the_fablab' was not loaded
- [TODO DEPLOY] add `MAX_IMAGE_SIZE` environment variable in `application.yml` and docker env

## v2.4.1 2016 October 11

- Fix a bug: unable to share a project/event without image on social networks
- Fix a bug: after creating an element in the admin calendar, browsing through the calendar and coming back cause the element to appear duplicated
- Fix a bug: after deleting an element in the admin calendar, the confirmation message is wrong and an error is logged in the console
- Fix a bug: erroneous syntax in docker env example file

## v2.4.0 2016 October 4

- RSS feeds to follow new projects and events published
- Use slugs in projects URL opened from notifications
- Ask for confirmation on machine deletion from the public view
- Ability to delete a training from the public view for an admin
- Project images will show in full-size on a click
- Add a checkbox "I accept to receive informations from the FabLab" on Sign-up dialog and user's profile
- Share project with Facebook/Twitter
- Display Fab-manager's version in "Powered by" label, when logged as admin
- Load translation locales from subdirectories
- Add wallet to user, client can pay total/partial reservation or subscription by wallet
- Public calendar for show all trainings/machines/events
- Display 'draft' badge on drafts in project galleries
- Add a 'new project' button in dashboard/my projects
- Open Projects: show the platform of origin even for local projects
- Ability to use HTML in machine specs and description
- Ability to manage project steps order
- Trainings are associated with a picture and an HTML textual description
- Public gallery of trainings with ability to view details or to book a training on its own calendar
- Ability to switch back to all trainings booking view
- Rename "Courses and Workshops" to "Events"
- Admin: Events can be associated with a theme and an age range
- Admin: Event categories, themes and age ranges can be customized
- Filter events by category, theme and age range in public view
- Ability to customise price's categories for the events
- Events can be associated with many custom price's categories, instead of only one "reduced price"
- Statistics views can trigger and display custom aggregations from ElasticSearch
- Machine hours/Trainings statistics: display number of tickets/hours available for booking
- Statistics will include informations abouts events category, theme and age range
- Ability to export the current statistics table to an Excel file
- Ability to export every statistics on a given dates range to an Excel file
- More fields in members exports
- Unified members, subscriptions and reservations exports with the new statistics exports
- Excel exports are now asynchronously generated and cached on the server for future identical requests
- Users have the ability to create an organizational profile when creating an account
- Organization informations will be used in invoices generation, if present
- Admins can create and enable/disable coupons. They can also notify an user about details of a coupon
- Users and admins can apply coupons's discounts to their shopping cart
- Send an email reminder and system notification some hours before a reservation happens
- Admins can toggle reminders on/off and customize the delay
- More file types allowed as project CAD attachements
- Project CAD attachements are now checked by MIME type in addition of extension check
- Project CAD attachement allowed are now configured in environment variables
- Project CAD attachement extensions allowed are shown next to input field
- Display strategy's name in SSO providers list
- SSO: documentation improved with an usage example
- SSO: mapped fields display their data type. Integers, booleans and dates allow some transformations.
- Fix a bug: project drafts are shown on public profiles
- Fix a bug: event category disappear when editing the event
- Fix a bug: machine name is not shown in plan edition
- Fix a bug: machine slots with tags are not displayed correctly on reservation calendar
- Fix a bug: avatar, address and organization details mapping from SSO were broken
- Fix a bug: in SSO configuration some valid endpoints were recognized as erroneous
- Fix a bug: clicking on the text in stripe's payment modal, does not validate the checkbox
- Fix a bug: move event reservation is not limited by admin settings (prior-delay & disable)
- Fix a bug: UI issues on small devices (dashboard + admin views)
- Fix a bug: embedded video not working in training/machine description
- Fix a bug: reordering project's steps trigger the unsaved-warning dialog
- Fix a bug: unable to compile assets in Docker with CoffeeScript error
- Fix a bug: do not force HTTPS for URLs in production environments
- [TODO DEPLOY] `rake fablab:es:build_availabilities_index`
- [TODO DEPLOY] `rake fablab:es:add_event_filters`
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] -> (only dev) `bundle install`
- [TODO DEPLOY] add `EXCEL_DATE_FORMAT`, `ALLOWED_EXTENSIONS` and `ALLOWED_MIME_TYPES` environment variable in `application.yml`
- [OPTIONAL] `rake fablab:fix:assign_category_to_uncategorized_events` (will put every non-categorized events into a new category called "No Category", to ease re-categorization)

## v2.3.1 2016 September 26

- Fix a bug: group cache filename too long

## v2.3.0 2016 June 28

- Public API with access management and online documentation
- Add json cache for machines, events, trainings
- Optimise sql query, avoid to N+1
- Projects URL are always composed with slug instead of ID
- Confirmation on project deletion
- Fix a bug: unable to deploy 2.2.0+ when PostgreSQL 'unaccent' extension was already active
- Fix a bug: some reservations was referencing reservables not present in database (#patch)
- [TODO DEPLOY] `bundle exec rake fablab:fix:reservations_not_existing_reservable` to apply #patch
- [TODO DEPLOY] -> (only dev) `bundle install` then (all) `rake db:migrate`

## v2.2.2 2016 June 23
- Fix some bugs: users with uncompleted account (sso imported) won't appear in statistics, in listings and in searches. Moreover, they won't block statistics generation
- Fix a bug: unable to display next results in statistics tables
- Admin: Category is mandatory when creating an event

## v2.2.1 2016 June 22
- Fix a bug: field User.merged_at should not be allowed to be mapped in SSO
- Fix a bug: integration test "user reservation without plan"
- Fix a bug: can't click for some seconds in Chrome 51
- Admin: statistics tables were paginated and optimized to improve load times.

## v2.2.0 2016 June 16
- Built-in support for extensions plug-ins
- User profile form: social networks links, personal website link, job and change profile visibility (public / private)
- User public profile: UI re-design with possible admin's customization
- Admin: Invoices list and users list are now loaded per 10 items to improve pages load time
- Admin: select member (eg. to buy a subscription for a member) is now loading the user's list dynamically when you type
- Project collaborators selection is now using a list dynamically loaded as you type
- Admin: select a training before monitoring its reservations -> improves page load time
- API: GET /api/trainings do not load nor send the associated availabilities until they are requested
- List of members is now loaded 10 members by 10, to improve page load time
- [TODO DEPLOY] Regenerate the theme stylesheet (easy way: Customization/General/Main colour -> "Save")
- [TODO DEPLOY] -> (only dev) `bundle install` then (all) `rake db:migrate`

## v2.1.2 2016 May 24
- Fix a bug: Google Analytics was not loaded and did not report any stats

## v2.1.1 2016 May 3
- Fix a bug concerning openlab projects initialization in production env
- Fix a bug: user is not redirected after changing is duplicated e-mail on the SSO provider

## v2.1.0 2016 May 2
- Add search feature on openlab projects : [Openlab-projects](https://github.com/sleede/openlab-projects)
- Add integration tests for main features
- Credits logic has been extracted into a microservice
- Improved UI list of projects
- Refactor interface for SSO profile completion
- Change interface for SSO/email already used
- Fix a bug: custom asset favicon-file favicon file is not set
- Fix a security issue: stripe card token is now checked on server side on new/renew subscription
- Translated notification e-mails into english language
- Subscription extension logic has been extracted into a microservice
