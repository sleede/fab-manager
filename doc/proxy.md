# Install Fab-manager behind a proxy

## Configure docker service

As root, create a service configuration file for docker:

```bash
mkdir -p /etc/systemd/system/docker.service.d
vi /etc/systemd/system/docker.service.d/http-proxy.conf
```

```unit file (systemd)
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080/"
Environment="HTTPS_PROXY=https://proxy.example.com:8080/"
Environment="NO_PROXY=localhost,example.com"
```

```bash
systemctl daemon-reload
systemctl restart docker
```

# Configure docker client

As root, create a configuration file for the docker client:

```bash
mkdir -p /root/.docker
vi /root/.docker/config.json
```

```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:8080",
      "httpsProxy": "https://proxy.example.com:8080",
      "noProxy": "localhost,example.com"
    }
  }
}
```

## Configure your terminal and run the installation

See the [production guide](production_readme.md) for more information and options about the setup command.

```bash
export http_proxy="http://proxy.example.com:8080" https_proxy="https://proxy.example.com:8080" no_proxy="localhost,example.com"
\curl -sSL setup.fab.mn | bash
```

