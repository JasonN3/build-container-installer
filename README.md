[![Build status](https://github.com/jasonn3/build-container-installer/actions/workflows/tests.yml/badge.svg?event=push)](https://github.com/jasonn3/build-container-installer/actions/workflows/tests.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/35a48e77e64f469ba19d60a1a1e0be71)](https://app.codacy.com/gh/JasonN3/build-container-installer/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# Build Container Installer Action

This action is used to generate an ISO for installing an OSTree stored in a container image. This utilizes the anaconda command `ostreecontainer`, which also supports bootc.

## Usage

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
      ${{ steps.build.outputs.iso_path }}
      ${{ steps.build.outputs.iso_path }}-CHECKSUM
    if-no-files-found: error
    retention-days: 0
    compression-level: 0
```

**See the [Wiki](https://github.com/JasonN3/build-container-installer/wiki) for development and usage information.**


## Star History

<a href="https://star-history.com/#jasonn3/build-container-installer&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=jasonn3/build-container-installer&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=jasonn3/build-container-installer&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=jasonn3/build-container-installer&type=Date" />
 </picture>
</a>
