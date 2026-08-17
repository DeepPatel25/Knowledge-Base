# Docker

Docker packages an application and its dependencies into an image that can run as an isolated container. This guide provides a practical command reference for working with images, containers, registries, volumes, and networks.

## Learning objectives

After completing this topic, you should be able to:

- Explain the relationship between Docker images and containers.
- Build, list, inspect, and remove images.
- Create and manage containers.
- Publish ports and pass configuration through environment variables.
- Inspect logs and open a shell in a running container.
- Pull and push images with Docker Hub.
- Persist data with volumes and bind mounts.
- Create user-defined container networks.
- Clean up unused Docker resources safely.

## Core concepts

```text
Dockerfile --build--> Image --run--> Container
                                      |      |
                                      |      +--> Network
                                      +---------> Volume or bind mount
```

- An **image** is an immutable application template.
- A **container** is a running or stopped instance of an image.
- A **registry**, such as Docker Hub, stores and distributes images.
- A **volume** stores persistent data independently of a container.
- A **network** allows containers to communicate with each other.

## Prerequisites

Install Docker Desktop on macOS or Windows, or Docker Engine on Linux. Verify the installation:

```bash
docker version
docker info
```

Run Docker commands only on systems and containers you are authorized to administer.

## Images

List local images:

```bash
docker image ls
```

Pull an image from Docker Hub:

```bash
docker pull nginx:alpine
```

Build an image from the `Dockerfile` in the current directory:

```bash
docker build -t my-app:1.0 .
```

Build without using cached layers:

```bash
docker build --no-cache -t my-app:1.0 .
```

Inspect an image:

```bash
docker image inspect my-app:1.0
```

Remove an image:

```bash
docker image rm my-app:1.0
```

Remove images that are not referenced by a container:

```bash
docker image prune
```

Review the items Docker plans to remove before confirming a prune command.

## Containers

List running containers:

```bash
docker container ls
```

List running and stopped containers:

```bash
docker container ls --all
```

Create and run a container:

```bash
docker run nginx:alpine
```

Run it in the background with a custom name:

```bash
docker run --detach --name web nginx:alpine
```

Publish container port `80` on host port `8080`, restricted to the local machine:

```bash
docker run --detach --name web --publish 127.0.0.1:8080:80 nginx:alpine
```

The service is then available at `http://localhost:8080`. Omitting `127.0.0.1` normally publishes the port on all host interfaces, which can expose the service to the network.

Pass an environment variable when creating a container:

```bash
docker run --env APP_ENV=development my-app:1.0
```

Avoid putting passwords or tokens directly on the command line because they can appear in shell history and process metadata. Prefer a secrets-management mechanism for sensitive values.

Start, stop, restart, or remove an existing container:

```bash
docker start web
docker stop web
docker restart web
docker rm web
```

Force removal only when the container cannot be stopped normally and its data is no longer needed:

```bash
docker rm --force web
```

## Inspect and troubleshoot containers

Show detailed container configuration and state:

```bash
docker inspect web
```

Read container logs:

```bash
docker logs web
```

Follow new log output:

```bash
docker logs --follow web
```

Show live resource usage:

```bash
docker stats
```

Open a shell in a running container when Bash is available:

```bash
docker exec -it web /bin/bash
```

Minimal images commonly provide `sh` instead:

```bash
docker exec -it web /bin/sh
```

Inspect the container's processes:

```bash
docker top web
```

## Docker Hub

Search Docker Hub:

```bash
docker search nginx
```

Authenticate interactively:

```bash
docker login
```

Tag a local image for a Docker Hub repository:

```bash
docker tag my-app:1.0 YOUR_DOCKERHUB_USERNAME/my-app:1.0
```

Push the tagged image:

```bash
docker push YOUR_DOCKERHUB_USERNAME/my-app:1.0
```

Remove locally stored registry credentials when finished:

```bash
docker logout
```

Use access tokens instead of account passwords where supported. Do not commit Docker credentials or a populated Docker client configuration file.

## Volumes and bind mounts

List volumes:

```bash
docker volume ls
```

Create and inspect a named volume:

```bash
docker volume create app-data
docker volume inspect app-data
```

Mount the named volume into a container:

```bash
docker run --mount type=volume,source=app-data,target=/var/lib/app my-app:1.0
```

The shorter `--volume` form is also supported:

```bash
docker run --volume app-data:/var/lib/app my-app:1.0
```

Bind-mount a host directory into a container:

```bash
docker run --mount type=bind,source="$(pwd)",target=/workspace my-app:1.0
```

A bind mount exposes the selected host path to the container. Use a read-only mount when the container should not modify the files:

```bash
docker run --mount type=bind,source="$(pwd)",target=/workspace,readonly my-app:1.0
```

Remove a named volume after confirming that its data is no longer required:

```bash
docker volume rm app-data
```

Remove unused local volumes:

```bash
docker volume prune
```

Removing a container does not automatically remove its named volumes.

## Networks

List Docker networks:

```bash
docker network ls
```

Create a user-defined bridge network:

```bash
docker network create app-network
```

Start containers on that network:

```bash
docker run --detach --name database --network app-network postgres:alpine
docker run --detach --name application --network app-network my-app:1.0
```

Containers on a user-defined network can reach each other by container name when the applications and ports are configured correctly.

Inspect or remove the network:

```bash
docker network inspect app-network
docker network rm app-network
```

Remove unused networks:

```bash
docker network prune
```

## Useful command pattern

Most Docker objects support a consistent management pattern:

```text
docker <object> ls
docker <object> inspect <name-or-id>
docker <object> rm <name-or-id>
docker <object> prune
```

Examples of `<object>` include `image`, `container`, `volume`, and `network`.

## Common mistakes

- Omitting an image tag and unintentionally using `latest`.
- Publishing a port to all host interfaces when only local access is needed.
- Storing secrets in an image, Dockerfile, environment variable command, or source repository.
- Writing important data only to a container's writable layer.
- Deleting a volume before confirming that its data is backed up.
- Using `docker exec` to make manual changes that are not captured in the Dockerfile.
- Running untrusted images without reviewing their source and requested privileges.
- Using `--privileged` or mounting the Docker socket without understanding the host-level access they provide.

## Cleanup

Inspect Docker disk usage:

```bash
docker system df
```

List resources before deleting them:

```bash
docker container ls --all
docker image ls
docker volume ls
docker network ls
```

Remove a stopped lab container and its test image:

```bash
docker container rm web
docker image rm nginx:alpine
```

Remove unused containers, networks, dangling images, and build cache:

```bash
docker system prune
```

`docker system prune` does not remove volumes by default. Read the confirmation prompt carefully, and do not add `--volumes` unless unused volume data can be permanently deleted.

## Hands-on checklist

- [ ] Pull a small image from Docker Hub.
- [ ] Run a named container in the background.
- [ ] Publish a container port to the host.
- [ ] Inspect the container and read its logs.
- [ ] Open a shell inside the container.
- [ ] Build and tag an image from a Dockerfile.
- [ ] Persist test data in a named volume.
- [ ] Connect two containers to a user-defined network.
- [ ] Stop and remove the lab containers.
- [ ] Review and clean up unused resources.

## Reference material

This guide was developed with the supplied *Docker CheatSheet ApnaCollege* as topic reference. Commands were normalized to current Docker CLI syntax and expanded with verification, security, and cleanup guidance.
