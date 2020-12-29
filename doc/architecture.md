# Architecture

## Root

`fab-manager/`
╠═ `.docker/` In development, data of the databases are stored in this untracked folder;
╠═ `.github/` Configuration of the GitHub repository;
╠═ `accounting/` When some accounting exports are generated in the application, they are saved in this untracked folder;
╠═ `app/` **The source code of the application**;
╠═ `bin/` Ruby-on-rails binaries;
╠═ `config/` Application and frameworks configurations are saved here. **Translations are saved here too**; 
╠═ `coverage/` Coveralls.io saves its temporary data into this untracked folder;
╠═ `db/` Database schema and migrations (ie. the history of the construction of the database);
╠═ `doc/` Various documentations about Fab-manager;
╠═ `docker/` Files used to build the docker image. Also: files to set up a development environment based on docker; 
╠═ `exports/` When some exports are generated in the application, they are saved in this untracked folder;
╠═ `imports/` When some files are imported to the application, they are saved in this untracked folder;
╠═ `invoices/` When some invoices are generated in the application, they are saved in this untracked folder;
╠═ `lib/` **Some more code of the application**. This code may not be loaded automatically;
╠═ `log/` When running, the application will produce some debug outputs, they are saved in this untracked folder;
╠═ `node_modules` Third party libraries for the front-end JS application are stored in this untracked folder by the package manager (yarn);
╠═ `payment_schedules`  When some payment schedules are generated in the application, they are saved in this untracked folder;
╠═ `plugins/` Some code can be dropped in that untracked folder to use plugins with Fab-manager;
╠═ `provision/` Scripts used to setup a development environment based on vagrant;
╠═ `public` Files that will be exposed to the world by the HTTP server (nginx). This includes the compilation result of the front-end application; 
╠═ `scripts/` Some bash scripts. Scripts ran during the upgrade phrase are located here;
╠═ `setup/` Everything needed to set up a new instance of Fab-manager, including the setup script;
╠═ `test/` Automated tests of the application (MiniTest);
╠═ `tmp/` Various temporary files are stored in this untracked folder;
╠═ `vendor/` (deprecated) Previously 3rd-party assets were stored here. Now, only the fonts for the PDF generation remains here;
╠═ `.browserslistrc` Required by babel (JS compiler) to specify target browsers for the compilation of the front-end application;
╠═ `.coveralls.yml` Configuration of coveralls.io;
╠═ `.dockerignore` List of files that won't be included in the docker image;
╠═ `.env` Environment variables for development and test environments;
╠═ `.eslitignore` List of files that won't be parsed by ESLint;
╠═ `.eslintrc` Configuration of the JS code quality checking (ESLint);
╠═ `.gemrc` Ruby gems configuration;
╠═ `.gitignore` List of files that won't be tracked by the version control system (git);
╠═ `.nvmrc` Version of node.js used in this project. This file is read by NVM in development environments;
╠═ `.rubocop.yml` Configuration of the Ruby code quality checking (Rubocop);
╠═ `.ruby-gemset` Used by RVM to isolate the gems of this application 
╠═ `.ruby-version` Version of Ruby used in this project. This file is read by RVM in development environments;
╠═ `babel.config.js` Configuration of babel (JS compiler);
╠═ `Capfile` (deprecated) Configuration of capistrano (previous deployment system);
╠═ `CHANGELOG.md` List of changes between releases of Fab-manager. Also contains deployment instructions for upgrading; 
╠═ `config.ru` This file is used by Rack-based servers to start the application;
╠═ `CONTRIBUTING.md` Contribution guidelines;
╠═ `crowdin.yml` Configuration of the translation management system (Crowdin);
╠═ `Dockerfile` This file list instructions to build the docker image of the application;
╠═ `env.example` Example of configuration for the environment variables, for development and test environments;
╠═ `Gemfile` List of third-party libraries used in the Ruby-on-Rails application;
╠═ `Gemfile.lock` Version lock of the ruby-on-rails dependencies;
╠═ `LICENSE.md` Publication licence of Fab-manager;
╠═ `package.json` List of third-party libraries used in the Javascript application. Also: version number of Fab-manager;
╠═ `postcss.config.js` Configuration of PostCSS (CSS compiler);
╠═ `Procfile` List the process ran by foreman when starting the application in development;
╠═ `Rakefile` Configuration of Rake (Ruby commands interpreter);
╠═ `README.md` Entrypoint for the documentation;
╠═ `tsconfig.json` Configuration of TypeScript;
╠═ `Vagrantfile` Configuration of Vagrant, for development environments;
╠═ `yarn.lock` Version lock of the javascript dependencies;
╚═ `yarn-error.log` This untracked file keeps logs of the package manager (yarn), if any error occurs; 

## Backend application

The backend application respects the Ruby-on-Rails conventions for MVC applications.
It mainly provides a REST-JSON API for the frontend application.
It also provides another REST-JSON API, open to the 3rd-party applications, and known as OpenAPI.

`fab-manager/`
╚═╦ `app/`
  ╠═ `controllers/` Controllers (MVC);
  ╠═ `doc/` Documentation for the OpenAPI;
  ╠═ `exceptions/` Custom errors;
  ╠═ `frontend/` **Source code for the frontend application**; 
  ╠═ `helpers/` System-wide libraries and utilities. Prefer using `services/` when it's possible;
  ╠═ `mailers/` Sending emails;
  ╠═ `models/` Models (MVC);
  ╠═ `pdfs/` PDF documents generation;
  ╠═ `policies/` Access policies for the API and OpenAPI endpoints;
  ╠═ `services/` Utilities arranged by data models; 
  ╠═ `sweepers/` Build cached version of some data;
  ╠═ `themes/` SASS files that overrides the frontend styles. We plan to move all styles here to build multiple themes;   
  ╠═ `uploaders/` Handling of the uploaded files
  ╠═ `validators/` Custom data validation (before saving);
  ╠═ `views/` Views (MVC)
  ╚═ `workers/` Asynchronous tasks run by Sidekiq

## Frontend application

The frontend application is historically an Angular.js MVC application.
We are moving, step-by-step, to an application based on React.js + Typescript.
For now, the main application is still using Angular.js but it uses some React.js components thanks to coatue-oss/react2angular.

`fab-manager/`
╚═╦ `app/`
  ╚═╦ `frontend/`
    ╠═ `images/` Static images used all over the frontend app;
    ╠═ `packs/` Entry points for webpack (bundler);
    ╠═╦ `src/`
    ║ ╠═╦ `javascript/`
    ║ ║ ╠═ `api/` (TS) New components to access the backend API; 
    ║ ║ ╠═ `components/` (TS) New React.js components;
    ║ ║ ╠═ `controllers/` (JS) Old Angular.js controllers for the views located in `app/frontend/templates`;
    ║ ║ ╠═ `directives/` (JS) Old Angular.js directives (interface components);
    ║ ║ ╠═ `filters/` (JS) Old Angular.js filters (processors transforming data);
    ║ ║ ╠═ `lib/` (TS) New utilities + (JS) Old external libraries customized; 
    ║ ║ ╠═ `models/` (TS) Typed interfaces reflecting the API data models;
    ║ ║ ╠═ `services/` (JS) Old Angular.js components to access the backend API; 
    ║ ║ ╠═ `typings/` (TS) Typed modules for non-JS/TS file types;
    ║ ║ ╠═ `app.js` Entrypoint for the angular.js application;
    ║ ║ ╠═ `plugins.js.erb` Entrypoint for embedding Fab-manager's plugins in the frontend application;
    ║ ║ ╚═ `router.js` Configuration for UI-Router (mapping between routes, controllers and templates)
    ║ ╚═ `stylesheets/` SASS source for the application style
    ╚═ `templates/` Angular.js views (HTML) 
