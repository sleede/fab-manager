# Open Projects

**This configuration is optional.**

You can configure your Fab-manager to synchronize every project with the [Open Projects platform](https://github.com/sleede/openlab-projects).
It's very simple and straightforward and in return, your users will be able to search over projects from all Fab-manager instances from within your platform.
The deal is fair, you share your projects and as reward you benefits from projects of the whole community.

If you want to try it, you can visit [this Fab-manager](https://fablab.lacasemate.fr/#!/projects) and see projects from different Fab-managers.

To start using this awesome feature, there are a few steps:
- send a mail to **contact@fab-manager.com** asking for your Open Projects client's credentials and giving them the name and the URL of your Fab-manager, they will give you an `App ID` and a `secret`
- fill in the value of the keys in Admin > Projects > Settings > Projects sharing
- export your projects to open-projects (if you already have projects created on your Fab-manager, unless you can skip that part) executing this command: `bundle exec rails fablab:openlab:bulk_export`

**IMPORTANT: please run your server in production mode.**

Go to your projects gallery and enjoy seeing your projects available from everywhere ! That's all.
