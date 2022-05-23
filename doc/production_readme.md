# Install Fab-manager in production with docker-compose

This document will guide you through all the steps needed to set up your Fab-manager app on a production server, based on a solution using Docker and Docker-compose.

In order to make it work, please use the same directories structure as described in this guide in your Fab-manager app folder.
You will need to be root through the rest of the setup.

##### Table of contents

1. [Preliminary steps](#preliminary-steps)<br/>
1.1. [Setup the server](#setup-the-server)<br/>
1.2. [Setup the domain name](#setup-the-domain-name)<br/>
1.3. [Connect through SSH](#connect-through-ssh)<br/>
1.4. [Prepare the server](#prepare-the-server)<br/>
2. [Install Fab-manager](#install-fab-manager)<br/>
3. [Useful commands](#useful-commands)
4. [Update Fab-manager](#update-fab-manager)<br/>
4.1. [Scripted update](#scripted-update)<br/>
4.2. [Update manually](#update-manually)<br/>
4.2.2. [Manual update steps](#manual-update-steps)<br/>
4.3. [Upgrade to the last version](#upgrade-to-the-last-version)<br/>
4.4. [Upgrade to a specific version](#upgrade-to-a-specific-version)<br/>
4.4.1. [With scripted update](#with-scripted-update)<br/>
4.4.2. [With manual update](#with-manual-update)<br/>

<a name="preliminary-steps"></a>
## Preliminary steps

<a name="setup-the-server"></a>
### Setup the server

There are [many hosting providers](https://duckduckgo.com/?q=vps+hosting) on the internet, providing affordable virtual private serveurs (VPS).
Choose one, depending on your budget, on the server's location, on the uptime guarantee, etc.

#### System requirements
##### Memory

If you do not plan to use the statistics module, you will need at least 2 GB of addressable memory (RAM + swap) to install and use Fab-manager.
We recommend 4 GB of RAM to take full advantage of Fab-manager and be able to use the statistics module.
If you have a large community (~ 200 active membres), we recommend 4 GB of RAM, even without the statistics module.

During the installation and the upgrades, the assets' compilation phase may fail if you do not have sufficient available memory.

##### CPU and Operating system

Supported operating systems are Ubuntu LTS 16.04+ and Debian 8+ with an x86 64-bits architecture.
This might work on other linux systems, and CPU architectures but this is untested for now, and we do not recommend for production purposes.

#### Software requirements
`curl` and `bash` are needed to retrieve and run the automated deployment scripts.  
Then the various scripts will check for their own dependencies.

Moreover, the main software dependencies to run fab-manager are [Docker](https://docs.docker.com/engine/installation/linux/docker-ce/debian/) v20.0 or above and [Docker Compose](https://docs.docker.com/compose/install/) 
They can be easily installed using the [`prepare-vps.sleede.com` script below](#prepare-the-server).

<a name="setup-the-domain-name"></a>
### Set up the domain name

There are [many domain name registrars](https://duckduckgo.com/?q=register+domain+name) on the internet, choose one that fit your needs.

1. Once done, buy a domain name on it
2. Replace the IP address of the domain with the IP address of your VPS (This is a DNS record of **type A**)
3. **Do not** try to access your domain name right away, DNS are not aware of the change yet so **WAIT** and be patient.
4. You may want to bind the subdomain `www.` to your main domain name. You can achieve this by creating a DNS record of **type CNAME**.

<a name="connect-through-ssh"></a>
### Connect through SSH

You can already connect to the server with this command: `ssh root@server-ip`. When DNS propagation will be done, you will be able to
connect to the server with `ssh root@your-domain-name`.

<a name="prepare-the-server"></a>
### Prepare the server

Before installing Fab-manager, we recommend you to:
- Upgrade your system
- Set up the server timezone
- Add at least 2 GB of swap memory
- Protect your SSH connection by forcing it through an RSA key

You can run the following script as root to easily perform all these operations:

```bash
\curl -sSL prepare-vps.sleede.com | bash
```

<a name="install-fab-manager"></a>
## Install Fab-manager

Run the following command to install Fab-manager.
This script will guide you through the installation process by checking the requirements and asking you the configuration elements.

```bash
\curl -sSL setup.fab.mn | bash
```

**OR**, if you don't want to install Fab-manager in `/apps/fabmanager`, use the following instead:
```bash
\curl -sSL setup.fab.mn | bash -s "/my/custom/path"
```

## Fab-manager for small configurations

If your server machine is not powerful, you can lower the system requirements by uninstalling ElasticSearch.
In order to remove ElasticSearch, you must **first** disable the statistics module from Customization > General > Modules.

Then, you can remove the `elasticsearch` service from the [docker-compose.yml](../setup/docker-compose.yml) file and restart the whole application:
```bash
docker compose down && docker compose up -d
```

Disabling ElasticSearch will save up to 800 Mb of memory. 

<a name="useful-commands"></a>
## Useful commands
Below, you'll find a collection of useful commands to control your instance with docker-compose.
Before using any of these commands, you must first `cd` into the app directory.

- Read again the environment variables and restart
```bash
docker compose down && docker compose up -d
```
- Open a bash prompt inside the app container
```bash
docker compose exec fabmanager bash
```
- Open the ruby console in the application
```bash
\curl -sSL run.fab.mn | bash
```
- Show services status
```bash
docker compose ps
```
- Run a command and provide it environment variables
```bash
docker compose run --rm -e VAR1=xxx -e VAR2=xxx fabmanager bundle exec rails my:command
```
<a name="update-fab-manager"></a>
## Update Fab-manager

When a new version is available, follow this procedure to update Fab-manager in a production environment.
You can subscribe to [this atom feed](https://github.com/sleede/fab-manager/releases.atom) to get notified when a new release comes out.

<a name="scripted-update"></a>
### Scripted update 

Starting with Fab-manager v4.5.0, you can upgrade Fab-manager in one single easy command, specified in the GitHub releases notes.
To upgrade multiple versions at once, read the GitHub release notes of all versions between your current version, and the target version.

**You MUST append all the arguments** of the upgrade commands, for **each version**, to the command you run.

E.g.
If you upgrade from 1.2.3 to 1.2.6, with the following release notes:
```markdown
## 1.2.4
\curl -sSL upgrade.fab.mn | bash -s -- -e "VAR=value"
## 1.2.5
\curl -sSL upgrade.fab.mn | bash -s -- -c "rails fablab:setup:command"
## 1.2.6
\curl -sSL upgrade.fab.mn | bash -s -- -p "rails fablab:do:things"
```
Then, you'll need to perform the upgrade with the following command:
```bash
\curl -sSL upgrade.fab.mn | bash -s -- -e "VAR=value" -p "rails fablab:do:things" -c "rails fablab:setup:command"
```
> ⚠ Do not confuse commands prefixed with `-p` and with `-c` because they are not intended to run at the same moment of the upgrade process. 

<a name="update-manually"></a>
### Update manually

**If you upgrade Fab-manager from a version >= 4.5.0, we recommend using the upgrade script above.**

> ⚠ If you are upgrading from a very outdated version, you must first upgrade to these versions in order:
> - v2.8.3
> - v3.1.2
> - v4.0.4
> - v4.4.6
> - v4.7.13
> After that, you can finally update to the last version

> ⚠ With versions < 4.3.3, you must replace `bundle exec rails` with `bundle exec rake` in all the commands above

<a name="manual-update-steps"></a>
#### Manual update steps

0. Read carefully the changelog of the last version you are upgrading to. It will contain important instructions about the upgrade process.

1. Go to your app folder

   `cd /apps/fabmanager`

2. Pull last docker images 

   `docker compose pull`

3. Stop the app

   `docker compose stop fabmanager`

4. Remove old assets

   `rm -Rf public/packs/ public/assets/`

5. Compile new assets

   `docker compose run --rm fabmanager bundle exec rails assets:precompile`

6. Run specific commands

   **Do not forget** to check if there are commands to run for your upgrade. Those commands 
   are always specified in the [CHANGELOG](https://github.com/sleede/fab-manager/blob/master/CHANGELOG.md) and prefixed by **[TODO DEPLOY]**.
 
   Those commands execute specific tasks and have to be run manually.
   You must prefix the commands starting by `rails...` or `rake...` with: `docker compose run --rm fabmanager bundle exec`.
   In any other cases, the other commands (like those invoking curl `\curl -sSL... | bash`) must not be prefixed.
   You can also ignore commands only applicable to development environnement, which are prefixed by `(dev)` in the CHANGELOG.

7. Restart all containers

   ```bash
     docker compose down
     docker compose up -d
   ```

You can check that all containers are running with `docker compose ps`.

<a name="upgrade-to-the-last-version"></a>
### Upgrade to the last version

It's the default behaviour as `docker compose pull` command will fetch the latest versions of the docker images. 
Be sure to run all the specific commands listed in the [CHANGELOG](https://github.com/sleede/fab-manager/blob/master/CHANGELOG.md) between your actual, and the new version in sequential order. 
__Example:__ to update from v2.4.0 to v2.4.3, you will run the specific commands for the v2.4.1, v2.4.2 and v2.4.3.

<a name="upgrade-to-a-specific-version"></a>
### Upgrade to a specific version

<a name="with-scripted-update"></a>
#### With scripted update
The easiest way to proceed is to provide the target version to the upgrade script, with the `-t` parameter, like this:
```bash
\curl -sSL upgrade.fab.mn | bash -s -- -t 4.7.13
```

<a name="with-manual-update"></a>
#### With manual update
If you are upgrading manually, edit your [/apps/fabmanager/docker-compose.yml](../setup/docker-compose.yml#L4) file and change the following line:
```yaml
image: sleede/fab-manager
```
For example, here we want to use the v3.1.2:
```yaml
image: sleede/fab-manager:release-v3.1.2
```
Then run the normal upgrade procedure. 
