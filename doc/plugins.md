# Plugins

Fab-manager has a system of plugins mainly inspired by [Discourse](https://github.com/discourse/discourse) architecture.

It enables you to write plugins which can:
- have its proper models and database tables
- have its proper assets (js & css)
- override existing behaviours of Fab-manager
- add features by adding views, controllers, ect...

To install a plugin, you just have to copy the plugin folder which contains its code into the folder `plugins` of Fab-manager.

You can see an example on the [repo of navinum gamification plugin](https://github.com/sleede/navinum-gamification)
