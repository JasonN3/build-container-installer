# Usage

This action is designed to be called from a GitHub workflow using the following format

```yaml
- name: Build ISO
  uses: jasonn3/build-container-installer@main
  id: build
  with:
    arch: ${{ env.ARCH}}
    image_name: ${{ env.IMAGE_NAME}}
    image_repo: ${{ env.IMAGE_REPO}}
    image_tag: ${{ env.IMAGE_TAG }}
    version: ${{ env.VERSION }}
    variant: ${{ env.VARIANT }}
    iso_name: ${{ env.IMAGE_NAME }}-${{ env.IMAGE_TAG }}-${{ env.VERSION }}.iso

# This example is for uploading your ISO as a Github artifact. You can do something similar using any cloud storage, so long as you copy the output
- name: Upload ISO as artifact
  id: upload
  uses: actions/upload-artifact@v4
  with:
    name: ${{ steps.build.outputs.iso_name }}
    path: |
      ${{ steps.build.outputs.iso_path }}/${{ steps.build.outputs.iso_name }}
      ${{ steps.build.outputs.iso_path }}/${{ steps.build.outputs.iso_name }}-CHECKSUM
    if-no-files-found: error
    retention-days: 0
    compression-level: 0
```

## Inputs

| Variable                | Description                                                                  | Default Value                                  | Action             | Container/Makefile |
| ----------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------- | ------------------ | ------------------ |
| additional_templates    | Space delimited list of additional Lorax templates to include                | \[empty\]                                      | :white_check_mark: | :white_check_mark: |
| arch                    | Architecture for image to build                                              | x86_64                                         | :white_check_mark: | :white_check_mark: |
| enrollment_password     | Used for supporting secure boot (requires SECURE_BOOT_KEY_URL to be defined) | container-installer                            | :white_check_mark: | :white_check_mark: |
| extra_boot_params       | Extra params used by grub to boot the anaconda installer                     | \[empty\]                                      | :white_check_mark: | :white_check_mark: |
| flatpak_remote_name     | Name of the Flatpak repo on the destination OS                               | flathub                                        | :white_check_mark: | :white_check_mark: |
| flatpak_remote_refs     | Space separated list of flatpak refs to install                              | \[empty\]                                      | :white_check_mark: | :white_check_mark: |
| flatpak_remote_refs_dir | Directory that contains files that list the flatpak refs to install          | \[empty\]                                      | :white_check_mark: | :white_check_mark: |
| flatpak_remote_url      | URL of the flatpakrepo file                                                  | <https://flathub.org/repo/flathub.flatpakrepo> | :white_check_mark: | :white_check_mark: |
| image_name              | Name of the source container image                                           | base                                           | :white_check_mark: | :white_check_mark: |
| image_repo              | Repository containing the source container image                             | quay.io/fedora-ostree-desktops                 | :white_check_mark: | :white_check_mark: |
| image_signed            | Whether the container image is signed. The policy to test the signing must be configured inside the container image | true    | :white_check_mark: | :white_check_mark: |
| image_src               | Overrides the source of the container image. Must be formatted for the skopeo copy command | \[empty\]                        | :white_check_mark: | :white_check_mark: |
| image_tag               | Tag of the source container image                                            | *VERSION*                                      | :white_check_mark: | :white_check_mark: |
| iso_name                | Name of the ISO you wish to output when completed                            | build/deploy.iso                               | :white_check_mark: | :white_check_mark: |
| make_target             | Overrides the default make target                                            | *ISO_NAME*-Checksum                            | :white_check_mark: | :x:                |
| repos                   | List of repo files for Lorax to use                                          | /etc/yum.repos.d/*.repo                        | :white_check_mark: | :white_check_mark: |
| rootfs_size             | The size (in GiB) for the squashfs runtime volume                            | 2                                              | :white_check_mark: | :white_check_mark: |
| secure_boot_key_url     | Secure boot key that is installed from URL location\*\*                      | \[empty\]                                      | :white_check_mark: | :white_check_mark: |
| variant                 | Source container variant\*                                                   | Server                                         | :white_check_mark: | :white_check_mark: |
| version                 | Fedora version of installer to build                                         | 39                                             | :white_check_mark: | :white_check_mark: |
| web_ui                  | Enable Anaconda WebUI (experimental)                                         | false                                          | :white_check_mark: | :white_check_mark: |

\*Available options for VARIANT can be found by running `dnf provides system-release`.
Variant will be the third item in the package name. Example: `fedora-release-kinoite-39-34.noarch` will be kinoite

\*\* If you need to reference a local file, you can use `file://*path*`

## Outputs

| Variable | Description                             | Usage                                            |
| -------- | ----------------------------------------| ------------------------------------------------ |
| iso_name | The name of the resulting .iso          | ${{ steps.YOUR_ID_FOR_ACTION.outputs.iso_name }} |
| iso_path | The path to the resulting .iso          | ${{ steps.YOUR_ID_FOR_ACTION.outputs.iso_path }} |
