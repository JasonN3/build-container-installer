# Using the Container

A container with `make install-deps` already run is provided at `ghcr.io/jasonn3/build-container-installer:latest`

To use the container file, run `podman run --privileged --volume .:/build-container-installer/build ghcr.io/jasonn3/build-container-installer:latest`.

This will create an ISO with the baked in defaults of the container image. The resulting file will be called `deploy.iso`

See [Customizing](#customizing) for information about customizing the ISO that gets created. The variable can either be defined as environment variables. All variable should be specified CAPITALIZED.
Examples:

Building an ISO to install Fedora 39
```bash
podman run --rm --privileged --volume .:/build-container-installer/build  ghcr.io/jasonn3/build-container-installer:latest VERSION=39 IMAGE_NAME=base IMAGE_TAG=39 VARIANT=Server
```

Building an ISO to install Fedora 40
```bash
podman run --rm --privileged --volume .:/build-container-installer/build  ghcr.io/jasonn3/build-container-installer:latest VERSION=40 IMAGE_NAME=base IMAGE_TAG=40 VARIANT=Server
```

The same commands are also available using `docker` by replacing `podman` with `docker` in each command.
