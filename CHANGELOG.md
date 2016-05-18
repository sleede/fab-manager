# Changelog Fab Manager

## Next release
- Ability for a user to add links to his social networks profiles and his personal website
- Ability for a user to change his visibility on the platform (public / private)
- UI re-design of user's public profile
- [TODO DEPLOY] Regenerate the theme stylesheet (easy way: Customization/General/Main colour -> "Save")
- [TODO DEPLOY] `bundle install` and `rake db:migrate`

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