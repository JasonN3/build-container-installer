![Build status](https://github.com/jasonn3/build-container-installer/actions/workflows/build-and-test.yml/badge.svg??event=push)

# Build Container Installer Action
This action is used to enerate an ISO for installing an OSTree stored in a container image. This utilizes the anaconda command `ostreecontainer`

## Usage
This action is designed to be called from a GitHub workflow using the following format
```yaml
- name: Build ISO
  uses: jasonn3/build-container-installer/v1.0.0
  id: build
  with:
    arch: ${{ env.ARCH}}
    image_name: ${{ env.IMAGE_NAME}}
    image_repo: ${{ env.IMAGE_REPO}}
    version: ${{ env.VERSION }}
    variant: ${{ env.VARIANT }}

# This example is for uploading your ISO as a Github artifact. You can do something similar using any cloud storage, so long as you copy the output
- name: Upload ISO as artifact
  id: upload
  uses: actions/upload-artifact@v4
  with:
    name: my_iso.iso
    path: |
      ${{ steps.build.outputs.iso_path }}
      ${{ steps.build.outputs.checksum-path }}
  if-no-files-found: error
  retention-days: 0
  compression-level: 0
```

See [Customizing](#customizing) for information about customizing the ISO that gets created using `with`

## Customizing
The following variables can be used to customize the created ISO.

### Inputs
| Variable          | Description                                              | Default Value                  |
| ----------------- | -------------------------------------------------------- | ------------------------------ |
| ARCH              | Architecture for image to build                          | x86_64                         |
| VERSION           | Fedora version of installer to build                     | 39                             |
| IMAGE_REPO        | Repository containing the source container image         | quay.io/fedora-ostree-desktops |
| IMAGE_NAME        | Name of the source container image                       | base                           |
| IMAGE_TAG         | Tag of the source container image                        | *VERSION*                      |
| EXTRA_BOOT_PARAMS | Extra params used by grub to boot the anaconda installer | \[empty\]                      |
| VARIANT           | Source container variant\*                               | Server                         |
| WEB_UI            | Enable Anaconda WebUI (experimental)                     | false                          |
| ISO_NAME          | Name of the ISO you wish to output when completed        | IMAGE_NAME-IMAGE_TAG           |

Available options for VARIANT can be found by running `dnf provides system-release`. 
Variant will be the third item in the package name. Example: `fedora-release-kinoite-39-34.noarch` will be kinoite

### Outputs
| Variable          | Description                                              | Usage                                            |
| ----------------- | -------------------------------------------------------- | ------------------------------------------------ |
| iso-path          | Path to ISO file that the action creates                 | ${{ steps.YOUR_ID_FOR_ACTION.outputs.iso_path }} |
| checksum-path     | Path to the checksum file that the action creates        | ${{ steps.YOUR_ID_FOR_ACTION.outputs.iso_path }} |

For outputs, see example above.

## Development
### Makefile
The Makefile contains all of the commands that are run in the action. There are separate targets for each file generated, however `make` can be used to generate the final image and `make clean` can be used to clean up the workspace. The resulting ISO will be stored in the `build` directory.

`make install-deps` can be used to install the necessary packages

See [Customizing](#customizing) for information about customizing the ISO that gets created.

### Container
A container with `make install-deps` already run is provided at `ghcr.io/jasonn3/build-container-installer:latest`

To use the container file, run `docker run --privileged --volume .:/build-container-installer/build ghcr.io/jasonn3/build-container-installer:latest`.

This will create an ISO with the baked in defaults of the container image.

See [Customizing](#customizing) for information about customizing the ISO that gets created. The variable can either be defined as environment variables.
Examples:

Building an ISO to install Fedora 38
```bash
docker run --rm --privileged --volume .:/build-container-installer/build  ghcr.io/jasonn3/build-container-installer:latest VERSION=38 IMAGE_NAME=base IMAGE_TAG=38 VARIANT=Server
```

Building an ISO to install Fedora 39
```bash
docker run --rm --privileged --volume .:/build-container-installer/build  ghcr.io/jasonn3/build-container-installer:latest VERSION=39 IMAGE_NAME=base IMAGE_TAG=39 VARIANT=Server
```

### VSCode Dev Container
There is a dev container configuration provided for development. By default it will use the existing container image available at `ghcr.io/jasonn3/build-container-installer:latest`, however, you can have it build a new image by editing `.devcontainer/devcontainer.json` and replacing `image` with `build`. `Ctrl+/` can be used to comment and uncomment blocks of code within VSCode.

The code from VSCode will be available at `/workspaces/build-container-installer` once the container has started.

Privileged is required for access to loop devices for lorax.

Use existing container image:
```
{
	"name": "Existing Dockerfile",
	// "build": {
	// 	"context": "..",
	// 	"dockerfile": "../Containerfile",
	// 	"args": {
	// 		"version": "39"
	// 	}
	// },
	"image": "ghcr.io/jasonn3/build-container-installer:latest",
	"overrideCommand": true,
	"shutdownAction": "stopContainer",
	"privileged": true
}
```

Build a new container image:
```
{
	"name": "Existing Dockerfile",
	"build": {
		"context": "..",
		"dockerfile": "../Containerfile",
		"args": {
			"version": "39"
		}
	},
	//"image": "ghcr.io/jasonn3/build-container-installer:latest",
	"overrideCommand": true,
	"shutdownAction": "stopContainer",
	"privileged": true
}
```

