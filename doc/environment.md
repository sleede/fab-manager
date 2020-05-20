# Environment Configuration

##### Table of Contents
1. [Introduction](#introduction)
2. [General settings](#general-settings)
3. [Internationalization settings](#internationalization-settings)
4. [Open projects settings](#open-projects-settings)


<a name="introduction"></a>
## Introduction

The following environment variables configure the addresses of the databases, some credentials, some application behaviours and the localization preferences.
If you are in a development environment, your can keep most of the default values, otherwise, in production, values must be configured carefully.

The settings in [.env](../env.example) configure the environment variables when the application run in development mode.
If you run the application in production with docker, the settings are localized in [config/env](../setup/env.example).

<a name="general-settings"></a>
## General settings
<a name="POSTGRES_HOST"></a>

    POSTGRES_HOST

DNS name or IP address of the server hosting the PostgreSQL database of the application (see [PostgreSQL](../README.md#postgresql)).
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`postgres` by default).
<a name="POSTGRES_PASSWORD"></a>

    POSTGRES_PASSWORD

Password for the PostgreSQL user, as specified in `database.yml` (default: `postgres`).
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).
When using docker-compose, the default configuration (with `postgres` user) does not uses any password as it is confined in the docker container.
<a name="REDIS_HOST"></a>

    REDIS_HOST

DNS name or IP address of the server hosting the redis database.
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`redis` by default).
<a name="ELASTICSEARCH_HOST"></a>

    ELASTICSEARCH_HOST

DNS name or IP address of the server hosting the elasticSearch database.
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`elasticsearch` by default).
<a name="SECRET_KEY_BASE"></a>

    SECRET_KEY_BASE

Used by the authentication system to generate random tokens, eg. for resetting passwords.
Used by Rails to verify the integrity of signed cookies.
You can generate such a random key by running `rails secret`.
<a name="STRIPE_API_KEY"></a><a name="STRIPE_PUBLISHABLE_KEY"></a>

    STRIPE_API_KEY & STRIPE_PUBLISHABLE_KEY

Key and secret used to identify you Stripe account through the API.
Retrieve them from https://dashboard.stripe.com/account/apikeys.

**MANDATORY**: Even if you don't want to charge your customers, you must fill this settings.
For this purpose, you can use a stripe account in test mode, which will provide you test keys.
If you change these keys during the application lifecycle, you must run `rails fablab:stripe:sync_members`, otherwise your users won't be able to do card payments.

Please note that Stripe have changed the naming of their keys. Here's the matching:
`STRIPE_API_KEY` = secret key
`STRIPE_PUBLISHABLE_KEY` = public key
<a name="STRIPE_CURRENCY"></a>

    STRIPE_CURRENCY

Currency used by stripe to charge the final customer.
See https://support.stripe.com/questions/which-currencies-does-stripe-support for a list of available 3-letters ISO code.

**BEWARE**: stripe currency cannot be changed during the application life.
Changing the currency after the application has already run, may result in several bugs and prevent the users to pay through stripe.
So set this setting carefully before starting the application for the first time.
<a name="INVOICE_PREFIX"></a>

    INVOICE_PREFIX

When payments are done on the platform, an invoice will be generated as a PDF file.
The PDF file name will be of the form "(INVOICE_PREFIX) - (invoice ID) _ (invoice date) .pdf".
<a name="FABLAB_WITHOUT_PLANS"></a>

    FABLAB_WITHOUT_PLANS

If set to 'true', the subscription plans will be fully disabled and invisible in the application.
It is not recommended to disable plans if at least one subscription was took on the platform.
<a name="FABLAB_WITHOUT_SPACES"></a>

    FABLAB_WITHOUT_SPACES

If set to 'false', enable the spaces management and reservation in the application.
It is not recommended to disable spaces if at least one space reservation was made on the system.
<a name="FABLAB_WITHOUT_ONLINE_PAYMENT"></a>

    FABLAB_WITHOUT_ONLINE_PAYMENT

If set to 'true', the online payment won't be available and the you'll be only able to process reservations when logged as admin.
Valid stripe API keys are still required, even if you don't require online payments.
<a name="FABLAB_WITHOUT_INVOICES"></a>

    FABLAB_WITHOUT_INVOICES

If set to 'true', the invoices will be disabled.
This is useful if you have your own invoicing system and you want to prevent Fab-manager from generating and sending invoices to members.
**Very important**: if you disable invoices, you still have to configure VAT in the interface to prevent errors in accounting and prices.
<a name="FABLAB_WITHOUT_WALLET"></a>

    FABLAB_WITHOUT_WALLET

If set to 'true', the wallet will be disabled.
This is useful if you won't use wallet system.
<a name="USER_CONFIRMATION_NEEDED_TO_SIGN_IN"></a>

    USER_CONFIRMATION_NEEDED_TO_SIGN_IN

If set to 'true' the users will need to confirm their email address to be able to sign in.
Set to 'false' if you don't want this behaviour.
<a name="EVENTS_IN_CALENDAR"></a>

    EVENTS_IN_CALENDAR

If set to 'true', the admin calendar will display the scheduled events in the current view, as read-only items.
<a name="DEFAULT_MAIL_FROM"></a>

    DEFAULT_MAIL_FROM

When sending notification mails, the platform will use this address to identify the sender.
<a name="DELIVERY_METHOD"></a>

    DELIVERY_METHOD

Configure the Rails' Action Mailer delivery method.
See http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
<a name="DEFAULT_HOST"></a><a name="DEFAULT_PROTOCOL"></a><a name="SMTP_ADDRESS"></a><a name="SMTP_PORT"></a><a name="SMTP_USER_NAME"></a><a name="SMTP_PASSWORD"></a><a name="SMTP_AUTHENTICATION"></a><a name="SMTP_ENABLE_STARTTLS_AUTO"></a><a name="SMTP_OPENSSL_VERIFY_MODE"></a><a name="SMTP_TLS"></a>

    DEFAULT_HOST, DEFAULT_PROTOCOL, SMTP_ADDRESS, SMTP_PORT, SMTP_USER_NAME, SMTP_PASSWORD, SMTP_AUTHENTICATION, SMTP_ENABLE_STARTTLS_AUTO, SMTP_OPENSSL_VERIFY_MODE & SMTP_TLS

When DELIVERY_METHOD is set to **smtp**, configure the SMTP server parameters.
See https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
DEFAULT_HOST is also used to configure Google Analytics.
<a name="RECAPTCHA_SITE_KEY"></a><a name="RECAPTCHA_SECRET_KEY"></a>

    RECAPTCHA_SITE_KEY, RECAPTCHA_SECRET_KEY

Configuration keys of Google ReCaptcha V2 (Checkbox).
This is optional, the captcha will be displayed on the sign-up form, only if these keys are provided.
<a name="DISQUS_SHORTNAME"></a>

    DISQUS_SHORTNAME

Unique identifier of your [Disqus](http://www.disqus.com) forum.
Disqus forums are used to allow visitors to comment on projects.
See https://help.disqus.com/customer/portal/articles/466208-what-s-a-shortname- for more information.
<a name="TWITTER_NAME"></a>

    TWITTER_NAME

Identifier of the Twitter account for Twitter share project, event or training
It will also be used for [Twitter Card analytics](https://dev.twitter.com/cards/analytics).
<a name="FACEBOOK_APP_ID"></a>

    FACEBOOK_APP_ID

This is optional. You can follow [this guide to get your personal App ID](https://developers.facebook.com/docs/apps/register).
If you do so, you'll be able to customize and get statistics about project shares on Facebook.
<a name="LOG_LEVEL"></a>

    LOG_LEVEL

This parameter configures the logs verbosity.
Available log levels can be found [here](http://guides.rubyonrails.org/debugging_rails_applications.html#log-levels).
<a name="ALLOWED_EXTENSIONS"></a>

    ALLOWED_EXTENSIONS

Exhaustive list of file's extensions available for public upload as project's CAO attachements.
Each item in the list must be separated from the others by a space char.
You will probably want to check that this list match the `ALLOWED_MIME_TYPES` values below.
Please consider that allowing file archives (eg. ZIP) or binary executable (eg. EXE) may result in a **dangerous** security issue and must be avoided in any cases.
<a name="ALLOWED_MIME_TYPES"></a>

    ALLOWED_MIME_TYPES

Exhaustive list of file's mime-types available for public upload as project's CAO attachements.
Each item in the list must be separated from the others by a space char.
You will probably want to check that this list match the `ALLOWED_EXTENSIONS` values above.
Please consider that allowing file archives (eg. application/zip) or binary executable (eg. application/exe) may result in a **dangerous** security issue and must be avoided in any cases.
<a name="MAX_IMAGE_SIZE"></a>

    MAX_IMAGE_SIZE

Maximum size (in bytes) allowed for image uploaded on the platform.
This parameter concerns events, plans, user's avatars, projects and steps of projects.
If this parameter is not specified the maximum size allowed will be 2MB.
<a name="MAX_CAO_SIZE"></a>

    MAX_CAO_SIZE

Maximum size (in bytes) allowed for CAO files uploaded on the platform, as project attachments.
If this parameter is not specified, the maximum size allowed will be 5MB.
<a name="MAX_IMPORT_SIZE"></a>

    MAX_IMPORT_SIZE

Maximum size (in bytes) allowed for import files uploaded on the platform.
Currently, this is only used to import users from a CSV file.
If this parameter is not specified, the maximum size allowed will be 5MB.
<a name="DISK_SPACE_MB_ALERT"></a>

    DISK_SPACE_MB_ALERT

Threshold in MB of the minimum free disk space available on the current mount point.
The check will run every weeks and if the threshold is exceeded, an alert will be sent to every administrators.
<a name="ADMIN_EMAIL"></a><a name="ADMIN_PASSWORD"></a>

    ADMIN_EMAIL, ADMIN_PASSWORD

Credentials for the first admin user created when seeding the project.
By default, theses variables are not present in application.yml because they are only used once, when running the database seed with the command `rails db:seed`.
<a name="SUPERADMIN_EMAIL"></a>

    SUPERADMIN_EMAIL

Optional email of the administrator account in charge of the system administration.
If specified, it will be hidden from the administrators list and it will exclusively receive the notifications related to the system administration.
If not specified, every admins will receive system administration notifications.
<a name="FORCE_VERSION_CHECK"></a>

    FORCE_VERSION_CHECK

In test and development environments, the version won't be check automatically, unless this variable is set to "true".
<a name="FEATURE_TOUR_DISPLAY"></a>

    FEATURE_TOUR_DISPLAY

When logged-in as an administrator, a feature tour will be triggered the first time you visit each section of the application.
You can change this behavior by setting this variable to one of the following values:
- "once" to keep the default behavior.
- "session" to display the tours each time you reopen the application.
- "manual" to prevent displaying the tours automatically; you'll still be able to trigger them by pressing the F1 key.

<a name="ALLOW_INSECURE_HTTP"></a>

    ALLOW_INSECURE_HTTP

In production and staging environments, the session cookie won't be sent to the server unless through the HTTPS protocol.
If you're using Fab-manager on a non-public network or for testing purposes, you can disable this behavior by setting this variable to `true`.
Please, ensure you know what you're doing, as this can lead to serious security issues. 

<a name="internationalization-settings"></a>
## Internationalization setting.
<a name="APP_LOCALE"></a>

    APP_LOCALE

Configure application's main localization and translation settings.

See `config/locales/app.*.yml` for a list of available locales. Default is **en**.
<a name="RAILS_LOCALE"></a>

    RAILS_LOCALE

Configure Ruby on Rails localization settings (currency, dates, number formats ...).

Please, be aware that **the configured locale will imply the CURRENCY symbol used to generate invoices**.

_Eg.: configuring **es-ES** will set the currency symbol to **€** but **es-MX** will set **$** as currency symbol, so setting the `RAILS_LOCALE` to simple **es** (without country indication) will probably not do what you expect._

See [config/locales/rails.*.yml](../config/locales) for a list of available locales. Default is **en**.

If your locale is not present in that list or any locale doesn't have your exact expectations, please open a pull request to share your modifications with the community and obtain a rebuilt docker image.
You can find templates of these files at https://github.com/svenfuchs/rails-i18n/tree/rails-4-x/rails/locale.
<a name="MOMENT_LOCALE"></a>

    MOMENT_LOCALE

Configure the moment.js library for l10n.

See [github.com/moment/momentlocale/*.js](https://github.com/moment/moment/tree/2.22.2/locale) for a list of available locales.
Default is **en** (even if it's not listed).
<a name="SUMMERNOTE_LOCALE"></a>

    SUMMERNOTE_LOCALE

Configure the javascript summernote editor for l10n.

See [github.com/summernote/summernote/lang/summernote-*.js](https://github.com/summernote/summernote/tree/v0.7.3/lang) for a list of available locales.
Default is **en-US** (even if it's not listed).
<a name="ANGULAR_LOCALE"></a>

    ANGULAR_LOCALE

Configure the locale for angular-i18n.

Please, be aware that **the configured locale will imply the CURRENCY displayed to front-end users.**

_Eg.: configuring **fr-fr** will set the currency symbol to **€** but **fr-ca** will set **$** as currency symbol, so setting the `ANGULAR_LOCALE` to simple **fr** (without country indication) will probably not do what you expect._

See [code.angularjs.org/i18n/angular-locale_*.js](https://code.angularjs.org/1.6.10/i18n/) for a list of available locales. Default is **en**.
<a name="FULLCALENDAR_LOCALE"></a>

    FULLCALENDAR_LOCALE

Configure the fullCalendar JS agenda library.

See [github.com/fullcalendar/fullcalendar/lang/*.js](https://github.com/fullcalendar/fullcalendar/tree/v2.3.1/lang) for a list of available locales. Default is **en-us**.
<a name="ELASTICSEARCH_LANGUAGE_ANALYZER"></a>

    ELASTICSEARCH_LANGUAGE_ANALYZER

This configure the language analyzer for indexing and searching in projects with ElasticSearch.
See [ElasticSearch guide](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/analysis-lang-analyzer.html) for a list of available analyzers.
<a name="TIME_ZONE"></a>

    TIME_ZONE

In Rails: set Time.zone default to the specified zone and make Active Record auto-convert to this zone. Run `rails time:zones:all` for a list of available time zone names.
Default is **UTC**.
<a name="WEEK_STARTING_DAY"></a>

    WEEK_STARTING_DAY

Configure the first day of the week in your locale zone (generally monday or sunday).
<a name="D3_DATE_FORMAT"></a>

    D3_DATE_FORMAT

Date format for dates displayed in statistics charts.
See [D3 Wiki](https://github.com/d3/d3-time-format/blob/v2.2.2/README.md#locale_format) for available formats.
<a name="UIB_DATE_FORMAT"></a>

    UIB_DATE_FORMAT

Date format for dates displayed and parsed in date pickers.
See [AngularUI documentation](https://angular-ui.github.io/bootstrap/#uibdateparser-s-format-codes) for a list available formats.

**BEWARE**: years format with less than 4 digits will result in problems because the system won't be able to distinct dates with the same less significant digits, eg. 50 could mean 1950 or 2050.
<a name="EXCEL_DATE_FORMAT"></a>

    EXCEL_DATE_FORMAT

Date format for dates shown in exported Excel files (eg. statistics)
See [Microsoft support](https://support.microsoft.com/en-us/kb/264372) for a list a available formats.
<a name="ENABLE_IN_CONTEXT_TRANSLATION"></a>

    ENABLE_IN_CONTEXT_TRANSLATION

If set to `true`, and the application in started into a staging environment, this will enable the Crowdin In-context translation layer for the front-end application.
See [Crowdin documentation](https://support.crowdin.com/in-context-localization/) for more details about this.
Accordingly, `RAILS_LOCALE` and `APP_LOCALE` must be configured to `zu`.
<a name="open-projects-settings"></a>
## OpenLab settings
<a name="OPENLAB_APP_ID"></a><a name="OPENLAB_APP_SECRET"></a>

    OPENLAB_APP_ID, OPENLAB_APP_SECRET

This configuration is optional and can only work in production mode.
It allows you to display a shared projects gallery and to share your projects with other fablabs.
Send an email to **contact@fab-manager.com** to get your OpenLab client's credentials.
<a name="OPENLAB_DEFAULT"></a>

    OPENLAB_DEFAULT

When set to false, the default display will be the local projects when browsing the projects gallery.
If not set or set to true, the projects from the OpenLab repository will be shown first.
<a name="OPENLAB_BASE_URI"></a>

    OPENLAB_BASE_URI

Set this variable to `https://openprojects.fab-manager.com` if you want to use the common projects repository or set it to your own OpenLab server.
