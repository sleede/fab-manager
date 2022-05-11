# How to configure Fab-manager to use a Single Sign-On authentication?

For this guide, we will use [GitHub](https://developer.github.com/v3/oauth/) as an example authentication provider, because it uses OAuth 2.0 which is currently implemented in Fab-manager, it has a standard implementation of the protocol and it is free to use for everyone.

- First, you must have a GitHub account. This is free, so create one if you don't have any.
  Visit https://github.com/join?source=login to create an account.

- Go to your Fab-manager's instance, login as an administrator, go to `Users management` and `Authentication`.
  Click `Add a new authentication provider`, and select _OAuth 2.0_ in the `Authentication type` drop-down list.
  In `name`, you can set whatever you want, but you must be aware that:
  1. You will need to type this name in a terminal to activate the provider, so prefer avoiding chars that must be escaped.
  2. This name will be occasionally displayed to end users, so prefer sweet and speaking names.

- You'll see an "Authorization Callback URL" field, generated based on what you typed previously. Copy the content of this field to your clipboard.

- Now, you will need to register your Fab-manager instance as an application in GitHub.
  Visit https://github.com/settings/applications/new to register your instance.
  - In `Application name`, we advise you to set the same name as your Fab-manager's instance title.
  - In `Homepage URL`, put the public URL where your Fab-manager's instance is located (eg. https://example.com).
  - In `Authorization callback URL`, you must paste the URL previously copied from Fa-manager. 

- You'll be redirected to a page displaying two important information: your **Client ID** and your **Client Secret**. Keep them safe, you'll need them to configure Fab-manager.

- Now go back to your Fab-manager's configuration interface and fulfill the remaining form with the following parameters:
  - **Server root URL**: `https://github.com` This is the domain name of the where the SSO server is located.
  - **Authorization endpoint**: `/login/oauth/authorize` This URL can be found [here](https://developer.github.com/v3/oauth/).
  - **Token Acquisition Endpoint**: `/login/oauth/access_token` This URL can be found [here](https://developer.github.com/v3/oauth/).
  - **Profile edition URL**: `https://github.com/settings/profile` This is the URL where you are directed when you click on `Edit profile` in your GitHub dashboard.
  - **Client identifier**: Your Client ID, collected just before.
  - **Client secret**: Your Client Secret, collected just before.

Please note the **common URL** must only contain the root domain (e.g. `http://github.com`), and the other parts of the URL must go to **Authorization endpoint** (e.g. `/login/oauth/authorize`) and **Token Acquisition Endpoint** (e.g. `/login/oauth/access_token`). 

- Then you will need to define the matching of the fields between the Fab-manager and what the external SSO can provide.
  Please note that the only mandatory field is `User.uid`.
  To continue with our GitHub example, you will need to look at [this documentation page](https://developer.github.com/v3/users/#get-the-authenticated-user) to know witch field can be mapped and how, and [this one](https://developer.github.com/v3/) to know the root URL of the API.
  - **Model**: `User`
  - **Field**: `uid`
  - **API endpoint URL**: `https://api.github.com/user` Here you can set a complete URL **OR** only an endpoint referring to the previously set **Common URL**.
  - **API type**: `JSON` Only JSON API are currently supported
  - **API fields**: `id` According to the GitHub API documentation, this is the name of the JSON field which uniquely identify the user.

  Once you have completed and validated the mapping's line, an information button will be available.
  A click on it will show you the type of data expected from the API and, in some cases, you'll be able to configure a transformation.
  For example, the `Profile.gender` field require a boolean attribute but your API may return strings like `man / woman`.
  In this case, you'll be able to configure a transformation for `man` <-> `true` and `woman` <-> `false`.

  Now, you are free to map more fields, like `Profile.github` to `html_url`, or `Profile.avatar` to `avatar_url`...

- Once you are done, your newly created authentication provider, will be marked as **Pending** in the authentication providers list.
  To set it as the current active provider, you must open a terminal on the hosting server (and/or container) and run the following commands:

```bash
# replace GitHub with the name of the provider you just created
rails fablab:auth:switch_provider[GitHub]
```

- As the command just prompted you, you have to re-compile the assets
  - In development, `rails tmp:clear` will do the job.
  - In production with Docker, `rm -rf public/packs`, followed by `docker-compose run --rm fabmanager bundle exec rails assets:precompile`
- Then restart the web-server or the container.
- Finally, to notify all existing users about the change (and send them their migration code/link), run:
```bash
rails fablab:auth:notify_changed
```
