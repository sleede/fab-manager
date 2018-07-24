# Changelog Fab Manager

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
- [TODO DEPLOY] `bundle install`
- [TODO DEPLOY] `rake db:seed`

## v2.6.4 2018 March 15

- Ability to share trainings on social medias
- Fix a bug: a reminder notification were sent for canceled reservations
- Fix a bug: sharing an event on facebook has HTML tags in the description
- Set Stripe API version, all fab-managers has to use this version because codebase relies on it
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
- [TODO DEPLOY] `bundle install`

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
- [TODO DEPLOY] `rake fablab:es_add_spaces`
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
- [TODO DEPLOY] `rake fablab:set_plans_slugs`

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
- [TODO DEPLOY] `rails runner StatisticCustomAggregation.destroy_all`, then `rake db:seed`, then `rake fablab:es_build_availabilities_index` (1)
- [TODO DEPLOY] `rake fablab:generate_stats[1095]` if you already has regenerated the statistics in the past, then they are very likely corrupted. Run this task to fix (2)

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
- Display fab-manager's version in "Powered by" label, when logged as admin
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
- [TODO DEPLOY] `rake fablab:es_build_availabilities_index`
- [TODO DEPLOY] `rake fablab:es_add_event_filters`
- [TODO DEPLOY] `rake db:migrate`
- [TODO DEPLOY] `bundle install`
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
- [TODO DEPLOY] `bundle install` and `rake db:migrate`

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
- [TODO DEPLOY] `bundle install` and `rake db:migrate`

## v2.1.2 2016 May 24
- Fix a bug: Google Analytics was not loaded and did not report any stats

## v2.1.1 2016 May 3
- Fix a bug concerning openlab projects initialization in production env
- Fix a bug: user is not redirected after changing is duplicated e-mail on the SSO provider

## v2.1.0 2016 May 2
- Add search feature on openlab projects : [Openlab-projects](https://github.com/LaCasemate/openlab-projects)
- Add integration tests for main features
- Credits logic has been extracted into a microservice
- Improved UI list of projects
- Refactor interface for SSO profile completion
- Change interface for SSO/email already used
- Fix a bug: custom asset favicon-file favicon file is not set
- Fix a security issue: stripe card token is now checked on server side on new/renew subscription
- Translated notification e-mails into english language
- Subscription extension logic has been extracted into a microservice
