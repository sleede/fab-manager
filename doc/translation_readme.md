# Fab-Manager translation documentation

This document will explain you what you need to know to contribute to the translation process of Fab-Manager.

##### Table of contents

1. [Translation](#i18n-translation)<br/>
1.1. [Front-end translations](#i18n-translation-front)<br/>
1.2. [Back-end translations](#i18n-translation-back)
2. [Configuration](#i18n-configuration)<br/>
2.1. [Settings](#i18n-settings)<br/>
2.2. [Applying changes](#i18n-apply)

<a name="i18n-translation"></a>
## Translation

First, consider that it can be a good idea to setup a development environment to contribute to the software translation.
This is not mandatory, but this will allow you to test your changes in context and see if anything went wrong, especially with the special syntaxes.
Please refer to the [development readme](development_readme.md) or to the [virtual machine instructions](virtual-machine.md) to setup such an environment. 

Once done, check the files located in `config/locales`:

- Front app translations (angular.js) are located in  `config/locales/app.scope.XX.yml`.
 Where scope has one the following meaning :
    - admin: translations of the administrator views (manage and configure the FabLab).
    - logged: translations of the end-user's views accessible only to connected users.
    - public: translation of end-user's views publicly accessible to anyone.
    - shared: translations shared by many views (like forms or buttons).
- Back app translations (Ruby on Rails) are located in  `config/locales/XX.yml`.
- Emails translations are located in `config/locales/mails.XX.yml`.
- Messages related to the authentication system are located in `config/locales/devise.XX.yml`.

If you plan to translate the application to a new locale, please consider that the reference translation is French.
Indeed, in some cases, the English texts/sentences can seems confuse or lack of context as they were originally translated from French.

To prevent syntax mistakes while translating locale files, we **STRONGLY advise** you to use a text editor which support syntax coloration for YML and Ruby.
As an example, [Visual Studio Code](https://code.visualstudio.com/), with the [Ruby extension](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby) and the [YAML extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) will do the job.

<a name="i18n-translation-front"></a>
### Front-end translations

Front-end translations uses [angular-translate](http://angular-translate.github.io) with some interpolations interpreted by angular.js and other interpreted by [MessageFormat](https://github.com/SlexAxton/messageformat.js/).
**These two kinds of interpolation use a near but different syntax witch SHOULD NOT be confused.**
Please refer to the official [angular-translate documentation](http://angular-translate.github.io/docs/#/guide/14_pluralization) before translating.

<a name="i18n-translation-back"></a>
### Back-end translations

Back-end translations uses the [Ruby on Rails syntax](http://guides.rubyonrails.org/i18n.html) but some complex interpolations are interpreted by [MessageFormat](https://github.com/format-message/message-format-rb) and are marked as it in comments.
**DO NOT confuse the syntaxes.**

In each cases, some inline comments are included in the localisation files.
They can be recognized as they start with the sharp character (#).
These comments are not required to be translated, they are intended to help the translator to have some context information about the sentence to translate.

You will also need to translate the invoice watermark, located in `app/pdfs/data/`.
You'll find there the [GIMP source of the image](app/pdfs/data/watermark.xcf), which is using [Rubik Mono One](https://fonts.google.com/specimen/Rubik+Mono+One) as font.
Use it to generate a similar localised PNG image which keep the default image size, as PDF are not responsive.


<a name="i18n-configuration"></a>
## Configuration

In development, locales configurations are made in [config/application.yml](../config/application.yml.default).
In production, locales configuration are made in the [config/env](../docker/env.example) file.
If you are in a development environment, your can keep the default values, otherwise, in production, values must be configured carefully.

<a name="i18n-settings"></a>
### Settings

Please refer to the [environment configuration documentation](environment.md#internationalization-settings)

<a name="i18n-apply"></a>
### Applying changes

After modifying any values concerning the localisation, restart the application (ie. web server) to apply these changes in the i18n configuration.
