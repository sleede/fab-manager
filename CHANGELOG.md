# Changelog Fab Manager

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