# PHP4/Apache 2.2 ambient for legacy projects

This docker image provides an environment to run old projects in
PHP 4 on modern machines.

## Installation

To set up the Docker environment for your system, follow these steps:

1. Build the Docker image using the command:

```sh
docker build -f Dockerfile.alpine -t php4-apache2 .
```

2. Once the image is built, start the environment with the command:

```sh
docker run -d --restart unless-stopped --name php4 -p 80:80 -v $(pwd)/app:/usr/local/apache2/htdocs -v $(pwd)/conf:/usr/local/apache2/conf -v $(pwd)/apache_logs/:/usr/local/apache2/logs php4-apache2:latest
```

3. Place project folders inside the 'app' directory. Virtual hosts can be configured within the 'conf/extra/httpd-vhosts.conf' file.

4. Access the container's shell with the command:

```sh
docker exec -it php4 sh
```

By using the 'restart unless-stopped' command, the container will automatically restart if it stops for any reason. Additionally, the 'add-host' flag ensures that the connection to the production DB3 is always added to the '/etc/hosts' file.
