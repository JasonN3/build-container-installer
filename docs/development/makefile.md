# Using the Makefile

The Makefile contains all the commands that are run in the action. There are separate targets for each file generated, however `make` can be used to generate the final image and `make clean` can be used to clean up the workspace. The resulting ISO will be stored in the `build` directory.

`make install-deps` can be used to install the necessary packages.

See [Inputs](usage#inputs) for information about the available parameters. All variables should be specified in CAPITALIZED form.
