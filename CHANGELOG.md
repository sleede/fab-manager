# Changelog Fab Manager

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
