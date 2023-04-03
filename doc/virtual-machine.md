# Virtual Machine Instructions

These instructions allow to deploy a testing or development instance of Fab-manager inside a virtual
machine, with most of the software dependencies installed automatically and avoiding to install a lot
of software and services directly on the host computer.

**Note:** The provision scripts configure the sofware dependencies to play nice with each other while
they are inside the same virtual environment but said configuration is not optimized for a production
environment.

**Note 2:** The perfomance of the application under the virtual machine depends on the resources that
the host can provide but will usually be much more slower than a production environment.

1. Install [Vagrant][vagrant] and [Virtual Box][virtualbox] (with the extension package).

2. Retrieve the project from Git

   ```bash
   git clone https://github.com/sleede/fab-manager
   ```

3. From the project directory, run:

   ```bash
   vagrant up
   ```

4. Once the virtual machine finished building, reload it with:

   ```bash
   vagrant reload
   ```

5. Log into the virtual machine with:

   ```bash
   vagrant ssh
   ```

6. While logged in, navigate to the project folder and install the Gemfile
   dependencies:

   ```bash
   bundle install
   yarn install
   ```

7. Set up the databases. (Note that you should provide the desired admin credentials and that these
    specific set of commands must be used to set up the database as some raw SQL instructions are
    included in the migrations. Password minimal length is 8 characters):

   ```bash
   rails db:schema:load
   # Be sure not to use the default values below in production
   ADMIN_EMAIL='admin@email' ADMIN_PASSWORD='adminpass' rails db:seed
   rails fablab:es:build_stats
   # for tests
   RAILS_ENV=test rails db:schema:load
   ```

8. Start the application and visit `localhost:3000` on your browser to check that it works:

   ```bash
   foreman s -p 3000
   ```

---
[vagrant]: https://www.vagrantup.com/downloads.html
[virtualbox]: https://www.virtualbox.org/wiki/Downloads
