# Architecture

Fab-manager was built on top of Ruby on Rails. Ruby on rails provides a REST API used by a single-page web application.
Historically, the front-end was using Angular.js but as this framework won't be supported anymore in a near future, we're progressively moving to React.

## Software dependencies
- Ruby 2.6
- Rails 5.2
- Sidekiq 6
- Docker

## Databases
- Redis 6
- Elasticsearch 5.6
- PostgreSQL 9.6

## Source-code architecture

`fab-manager/`<br>
`╠═ .docker/` In development, data of the databases are stored in this untracked folder;<br>
`╠═ .github/` Configuration of the GitHub repository;<br>
`╠═ accounting/` When some accounting exports are generated in the application, they are saved in this untracked folder;<br>
`╠═ app/` **The source code of the application**;<br>
`╠═ bin/` Ruby-on-rails binaries;<br>
`╠═ config/` Application and frameworks configurations are saved here. **Translations are saved here too**; <br>
`╠═ coverage/` Coveralls.io saves its temporary data into this untracked folder;<br>
`╠═ db/` Database schema and migrations (ie. the history of the construction of the database);<br>
`╠═ doc/` Various documentations about Fab-manager;<br>
`╠═ docker/` Files used to build the docker image. Also: files to set up a development environment based on docker; <br>
`╠═ exports/` When some exports are generated in the application, they are saved in this untracked folder;<br>
`╠═ imports/` When some files are imported to the application, they are saved in this untracked folder;<br>
`╠═ invoices/` When some invoices are generated in the application, they are saved in this untracked folder;<br>
`╠═ lib/` **Some more code of the application**. This code may not be loaded automatically;<br>
`╠═ log/` When running, the application will produce some debug outputs, they are saved in this untracked folder;<br>
`╠═ node_modules` Third party libraries for the front-end JS application are stored in this untracked folder by the package manager (yarn);<br>
`╠═ payment_schedules`  When some payment schedules are generated in the application, they are saved in this untracked folder;<br>
`╠═ plugins/` Some code can be dropped in that untracked folder to use plugins with Fab-manager;<br>
`╠═ provision/` Scripts used to setup a development environment based on vagrant;<br>
`╠═ public` Files that will be exposed to the world by the HTTP server (nginx). This includes the compilation result of the front-end application; <br>
`╠═ scripts/` Some bash scripts. Scripts ran during the upgrade phrase are located here;<br>
`╠═ setup/` Everything needed to set up a new instance of Fab-manager, including the setup script;<br>
`╠═ test/` Automated tests of the application (MiniTest);<br>
`╠═ tmp/` Various temporary files are stored in this untracked folder;<br>
`╠═ vendor/` (deprecated) Previously 3rd-party assets were stored here. Now, only the fonts for the PDF generation remains here;<br>
`╠═ .browserslistrc` Required by babel (JS compiler) to specify target browsers for the compilation of the front-end application;<br>
`╠═ .coveralls.yml` Configuration of coveralls.io;<br>
`╠═ .dockerignore` List of files that won't be included in the docker image;<br>
`╠═ .env` Environment variables for development and test environments;<br>
`╠═ .eslitignore` List of files that won't be parsed by ESLint;<br>
`╠═ .eslintrc` Configuration of the JS code quality checking (ESLint);<br>
`╠═ .gemrc` Ruby gems configuration;<br>
`╠═ .gitignore` List of files that won't be tracked by the version control system (git);<br>
`╠═ .nvmrc` Version of node.js used in this project. This file is read by NVM in development environments;<br>
`╠═ .rubocop.yml` Configuration of the Ruby code quality checking (Rubocop);<br>
`╠═ .ruby-gemset` Used by RVM to isolate the gems of this application;<br>
`╠═ .ruby-version` Version of Ruby used in this project. This file is read by RVM in development environments;<br>
`╠═ babel.config.js` Configuration of babel (JS compiler);<br>
`╠═ Capfile` (deprecated) Configuration of capistrano (previous deployment system);<br>
`╠═ CHANGELOG.md` List of changes between releases of Fab-manager. Also contains deployment instructions for upgrading; <br>
`╠═ config.ru` This file is used by Rack-based servers to start the application;<br>
`╠═ CONTRIBUTING.md` Contribution guidelines;<br>
`╠═ crowdin.yml` Configuration of the translation management system (Crowdin);<br>
`╠═ Dockerfile` This file list instructions to build the docker image of the application;<br>
`╠═ env.example` Example of configuration for the environment variables, for development and test environments;<br>
`╠═ Gemfile` List of third-party libraries used in the Ruby-on-Rails application;<br>
`╠═ Gemfile.lock` Version lock of the ruby-on-rails dependencies;<br>
`╠═ LICENSE.md` Publication licence of Fab-manager;<br>
`╠═ package.json` List of third-party libraries used in the Javascript application. Also: version number of Fab-manager;<br>
`╠═ postcss.config.js` Configuration of PostCSS (CSS compiler);<br>
`╠═ Procfile` List the process ran by foreman when starting the application in development;<br>
`╠═ Rakefile` Configuration of Rake (Ruby commands interpreter);<br>
`╠═ README.md` Entrypoint for the documentation;<br>
`╠═ tsconfig.json` Configuration of TypeScript;<br>
`╠═ Vagrantfile` Configuration of Vagrant, for development environments;<br>
`╠═ yarn.lock` Version lock of the javascript dependencies;<br>
`╚═ yarn-error.log` This untracked file keeps logs of the package manager (yarn), if any error occurs;

## Backend application

The backend application respects the Ruby-on-Rails conventions for MVC applications.
It mainly provides a REST-JSON API for the frontend application.
It also provides another REST-JSON API, open to the 3rd-party applications, and known as OpenAPI.

`fab-manager/`<br>
`╚═╦ app/`<br>
`  ╠═ controllers/` Controllers (MVC);<br>
`  ╠═ doc/` Documentation for the OpenAPI;<br>
`  ╠═ exceptions/` Custom errors;<br>
`  ╠═ frontend/` **Source code for the frontend application**; <br>
`  ╠═ helpers/` System-wide libraries and utilities. Prefer using `services/` when it's possible;<br>
`  ╠═ mailers/` Sending emails;<br>
`  ╠═ models/` Models (MVC);<br>
`  ╠═ pdfs/` PDF documents generation;<br>
`  ╠═ policies/` Access policies for the API and OpenAPI endpoints;<br>
`  ╠═ services/` Utilities arranged by data models; <br>
`  ╠═ themes/` SASS files that overrides the frontend styles. We plan to move all styles here to build multiple themes;   <br>
`  ╠═ uploaders/` Handling of the uploaded files<br>
`  ╠═ validators/` Custom data validation (before saving);<br>
`  ╠═ views/` Views (MVC)<br>
`  ╚═ workers/` Asynchronous tasks run by Sidekiq

## Frontend application

The frontend application is historically an Angular.js MVC application.
We are moving, step-by-step, to an application based on React.js + Typescript.
For now, the main application is still using Angular.js but it uses some React.js components thanks to coatue-oss/react2angular.

`fab-manager/`<br>
`╚═╦ app/`<br>
`  ╚═╦ frontend/`<br>
`    ╠═ images/` Static images used all over the frontend app;<br>
`    ╠═ packs/` Entry points for webpack (bundler);<br>
`    ╠═╦ src/`<br>
`    ║ ╠═╦ javascript/`<br>
`    ║ ║ ╠═ api/` (TS) New components to access the backend API; <br>
`    ║ ║ ╠═ components/` (TS) New React.js components;<br>
`    ║ ║ ╠═ controllers/` (JS) Old Angular.js controllers for the views located in `app/frontend/templates`;<br>
`    ║ ║ ╠═ directives/` (JS) Old Angular.js directives (interface components);<br>
`    ║ ║ ╠═ filters/` (JS) Old Angular.js filters (processors transforming data);<br>
`    ║ ║ ╠═ lib/` (TS) New utilities + (JS) Old external libraries customized; <br>
`    ║ ║ ╠═ models/` (TS) Typed interfaces reflecting the API data models;<br>
`    ║ ║ ╠═ services/` (JS) Old Angular.js components to access the backend API; <br>
`    ║ ║ ╠═ typings/` (TS) Typed modules for non-JS/TS file types;<br>
`    ║ ║ ╠═ app.js` Entrypoint for the angular.js application;<br>
`    ║ ║ ╠═ plugins.js.erb` Entrypoint for embedding Fab-manager's plugins in the frontend application;<br>
`    ║ ║ ╚═ router.js` Configuration for UI-Router (mapping between routes, controllers and templates)<br>
`    ║ ╚═ stylesheets/` SASS source for the application style<br>
`    ╚═ templates/` Angular.js views (HTML)
