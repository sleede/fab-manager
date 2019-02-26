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

The settings in [config/application.yml](../config/application.yml.default) configure the environment variables when the application run in development mode.
If you run the application in production with docker, the settings are localized in [config/env](../docker/env.example).

<a name="general-settings"></a>
## General settings


    POSTGRES_HOST

DNS name or IP address of the server hosting the PostgreSQL database of the application (see [PostgreSQL](../README.md#postgresql)).
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).

    POSTGRES_PASSWORD

Password for the PostgreSQL user, as specified in `database.yml`.
Please see [Setup the FabManager database in PostgreSQL](../README.md#setup-fabmanager-in-postgresql) for information on how to create a user and set his password.
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).

    REDIS_HOST

DNS name or IP address of the server hosting the redis database.

    ELASTICSEARCH_HOST

DNS name or IP address of the server hosting the elasticSearch database.

    SECRET_KEY_BASE

Used by the authentication system to generate random tokens, eg. for resetting passwords.
Used by Rails to verify the integrity of signed cookies.
You can generate such a random key by running `rake secret`.

    STRIPE_API_KEY & STRIPE_PUBLISHABLE_KEY

Key and secret used to identify you Stripe account through the API.
Retrieve them from https://dashboard.stripe.com/account/apikeys.

**MANDATORY**: Even if you don't want to charge your customers, you must fill this settings. 
For this purpose, you can use a stripe account in test mode, which will provide you test keys.

    STRIPE_CURRENCY

Currency used by stripe to charge the final customer.
See https://support.stripe.com/questions/which-currencies-does-stripe-support for a list of available 3-letters ISO code.

**BEWARE**: stripe currency cannot be changed during the application life.
Changing the currency after the application has already run, may result in several bugs and prevent the users to pay through stripe.
So set this setting carefully before starting the application for the first time.

    INVOICE_PREFIX

When payments are done on the platform, an invoice will be generated as a PDF file.
The PDF file name will be of the form "(INVOICE_PREFIX) - (invoice ID) _ (invoice date) .pdf"

    FABLAB_WITHOUT_PLANS

If set to 'true', the subscription plans will be fully disabled and invisible in the application.
It is not recommended to disable plans if at least one subscription was took on the platform.

    FABLAB_WITHOUT_SPACES

If set to 'false', enable the spaces management and reservation in the application.
It is not recommended to disable spaces if at least one space reservation was made on the system.

    DEFAULT_MAIL_FROM

When sending notification mails, the platform will use this address to identify the sender.

    DELIVERY_METHOD

Configure the Rails' Action Mailer delivery method.
See http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.

    DEFAULT_HOST, DEFAULT_PROTOCOL, SMTP_ADDRESS, SMTP_PORT, SMTP_USER_NAME, SMTP_PASSWORD, SMTP_AUTHENTICATION, SMTP_ENABLE_STARTTLS_AUTO & SMTP_OPENSSL_VERIFY_MODE

When DELIVERY_METHOD is set to **smtp**, configure the SMTP server parameters.
See https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
DEFAULT_HOST is also used to configure Google Analytics.

    GA_ID

Identifier of your Google Analytics account.

    DISQUS_SHORTNAME

Unique identifier of your [Disqus](http://www.disqus.com) forum.
Disqus forums are used to allow visitors to comment on projects.
See https://help.disqus.com/customer/portal/articles/466208-what-s-a-shortname- for more information.

    TWITTER_NAME

Identifier of the Twitter account, from witch the last tweet will be fetched and displayed on the home page.
This value can be graphically overridden during the application's lifecycle in Admin/Customization/Home page/Twitter Feed.
It will also be used for [Twitter Card analytics](https://dev.twitter.com/cards/analytics).

    TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN & TWITTER_ACCESS_TOKEN_SECRET

Keys and secrets to access the twitter API.
Retrieve them from https://apps.twitter.com

    FACEBOOK_APP_ID

This is optional. You can follow [this guide to get your personal App ID](https://developers.facebook.com/docs/apps/register).
If you do so, you'll be able to customize and get statistics about project shares on Facebook.

    LOG_LEVEL

This parameter configures the logs verbosity.
Available log levels can be found [here](http://guides.rubyonrails.org/debugging_rails_applications.html#log-levels).

    ALLOWED_EXTENSIONS

Exhaustive list of file's extensions available for public upload as project's CAO attachements.
Each item in the list must be separated from the others by a space char.
You will probably want to check that this list match the `ALLOWED_MIME_TYPES` values below.
Please consider that allowing file archives (eg. ZIP) or binary executable (eg. EXE) may result in a **dangerous** security issue and must be avoided in any cases.

    ALLOWED_MIME_TYPES

Exhaustive list of file's mime-types available for public upload as project's CAO attachements.
Each item in the list must be separated from the others by a space char.
You will probably want to check that this list match the `ALLOWED_EXTENSIONS` values above.
Please consider that allowing file archives (eg. application/zip) or binary executable (eg. application/exe) may result in a **dangerous** security issue and must be avoided in any cases.

    MAX_IMAGE_SIZE

Maximum size (in bytes) allowed for image uploaded on the platform.
This parameter concerns events, plans, user's avatars, projects and steps of projects.
If this parameter is not specified the maximum size allowed will be 2MB.

    DISK_SPACE_MB_ALERT

Threshold in MB of the minimum free disk space available on the current mount point.
The check will run every weeks and if the threshold is exceeded, an alert will be sent to every administrators. 

    ADMIN_EMAIL, ADMIN_PASSWORD

Credentials for the first admin user created when seeding the project. (not present in application.yml because they are only used once when running the database seed with the command `rake db:seed`)


<a name="internationalization-settings"></a>
## Internationalization settings

    APP_LOCALE

Configure application's main localization and translation settings.

See `config/locales/app.*.yml` for a list of available locales. Default is **en**.

    RAILS_LOCALE

Configure Ruby on Rails localization settings (currency, dates, number formats ...).

Please, be aware that **the configured locale will imply the CURRENCY symbol used to generate invoices**.

_Eg.: configuring **es-ES** will set the currency symbol to **€** but **es-MX** will set **$** as currency symbol, so setting the `RAILS_LOCALE` to simple **es** (without country indication) will probably not do what you expect._

See [config/locales/rails.*.yml](../config/locales) for a list of available locales. Default is **en**.

If your locale is not present in that list or any locale doesn't have your exact expectations, please open a pull request to share your modifications with the community and obtain a rebuilt docker image.
You can find templates of these files at https://github.com/svenfuchs/rails-i18n/tree/rails-4-x/rails/locale.

    MOMENT_LOCALE

Configure the moment.js library for l10n.

See [github.com/moment/momentlocale/*.js](https://github.com/moment/moment/tree/2.22.2/locale) for a list of available locales.
Default is **en** (even if it's not listed).

    SUMMERNOTE_LOCALE

Configure the javascript summernote editor for l10n.

See [github.com/summernote/summernote/lang/summernote-*.js](https://github.com/summernote/summernote/tree/v0.7.3/lang) for a list of available locales.
Default is **en-US** (even if it's not listed).

    ANGULAR_LOCALE

Configure the locale for angular-i18n.

Please, be aware that **the configured locale will imply the CURRENCY displayed to front-end users.**

_Eg.: configuring **fr-fr** will set the currency symbol to **€** but **fr-ca** will set **$** as currency symbol, so setting the `ANGULAR_LOCALE` to simple **fr** (without country indication) will probably not do what you expect._

See [code.angularjs.org/i18n/angular-locale_*.js](https://code.angularjs.org/1.6.10/i18n/) for a list of available locales. Default is **en**.

    MESSAGEFORMAT_LOCALE

Configure the messageformat.js library, used by angular-translate.

See [github.com/messageformat/messageformat/locale/*.js](https://github.com/messageformat/messageformat/tree/v0.1.8/locale) for a list of available locales.

    FULLCALENDAR_LOCALE

Configure the fullCalendar JS agenda library.

See [github.com/fullcalendar/fullcalendar/lang/*.js](https://github.com/fullcalendar/fullcalendar/tree/v2.3.1/lang) for a list of available locales. Default is **en-us**.

    ELASTICSEARCH_LANGUAGE_ANALYZER

This configure the language analyzer for indexing and searching in projects with ElasticSearch.
See [ElasticSearch guide](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/analysis-lang-analyzer.html) for a list of available analyzers.

    TIME_ZONE

In Rails: set Time.zone default to the specified zone and make Active Record auto-convert to this zone. Run `rake time:zones:all` for a list of available time zone names.
Default is **UTC**.

    WEEK_STARTING_DAY

Configure the first day of the week in your locale zone (generally monday or sunday).

    D3_DATE_FORMAT

Date format for dates displayed in statistics charts.
See [D3 Wiki](https://github.com/mbostock/d3/wiki/Time-Formatting#format) for available formats.

    UIB_DATE_FORMAT

Date format for dates displayed and parsed in date pickers.
See [AngularUI documentation](https://angular-ui.github.io/bootstrap/#uibdateparser-s-format-codes) for a list available formats.

**BEWARE**: years format with less than 4 digits will result in problems because the system won't be able to distinct dates with the same less significant digits, eg. 50 could mean 1950 or 2050.

    EXCEL_DATE_FORMAT

Date format for dates shown in exported Excel files (eg. statistics)
See [Microsoft support](https://support.microsoft.com/en-us/kb/264372) for a list a available formats.

<a name="open-projects-settings"></a>
## Open projects settings

This configuration is optional and can only work in production mode.

    OPENLAB_APP_ID, OPENLAB_APP_SECRET

Send an email to **contact@fab-manager.com** to get your Open Projects client's credentials.
