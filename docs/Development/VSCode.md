# Using the VSCode Dev Container

There is a dev container configuration provided for development. By default it will use the existing container image available at `ghcr.io/jasonn3/build-container-installer:latest`, however, you can have it build a new image by editing `.devcontainer/devcontainer.json` and replacing `image` with `build`. `Ctrl+/` can be used to comment and uncomment blocks of code within VSCode.

The code from VSCode will be available at `/workspaces/build-container-installer` once the container has started.

Privileged is required for access to loop devices for lorax.

## Use existing container image:

```diff
{
  "name": "Existing Image",
- "build": {
-   "context": "..",
-   "dockerfile": "../Containerfile",
-  "args": {
-     "version": "39"
-   }
- },
+ "image": "ghcr.io/jasonn3/build-container-installer:latest",
  "overrideCommand": true,
  "shutdownAction": "stopContainer",
  "privileged": true
}
```

## Build a new container image:

```diff
{
  "name": "New Image",
+ "build": {
+   "context": "..",
+   "dockerfile": "../Containerfile",
+   "args": {
+     "version": "39"
+   }
+ },
- "image": "ghcr.io/jasonn3/build-container-installer:latest",
  "overrideCommand": true,
  "shutdownAction": "stopContainer",
  "privileged": true
}
```

