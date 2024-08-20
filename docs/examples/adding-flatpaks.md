# Adding Flatpaks

- [Directly using refs](#directly-using-refs)
- [Using a directory](#using-a-directory)

## Directly using refs

Action:
Specify the following in your workflow:

```yaml
- name: Build ISO
  uses: jasonn3/build-container-installer@main
  id: build
  with:
    flatpak_remote_name: flathub
    flatpak_remote_url: https://flathub.org/repo/flathub.flatpakrepo
    flatpak_remote_refs: app/org.videolan.VLC/x86_64/stable runtime/org.kde.Platform/x86_64/5.15-23.08
```

Podman:
Run the following command:

```bash
podman run --privileged --volume ./:/github/workspace/ ghcr.io/jasonn3/build-container-installer:main \
          FLATPAK_REMOTE_NAME=flathub \
          FLATPAK_REMOTE_URL=https://flathub.org/repo/flathub.flatpakrepo \
          FLATPAK_REMOTE_REFS="app/org.videolan.VLC/x86_64/stable runtime/org.kde.Platform/x86_64/5.15-23.08"
```

---

## Using a directory

Action:

1. Create a directory within your GitHub repo named flatpak_refs
1. Create a file within flatpak_refs with the following content

```plaintext
app/org.videolan.VLC/x86_64/stable
runtime/org.kde.Platform/x86_64/5.15-23.08
```

Specify the following in your workflow:

```yaml
- name: Build ISO
  uses: jasonn3/build-container-installer@main
  id: build
  with:
    flatpak_remote_name: flathub
    flatpak_remote_url: https://flathub.org/repo/flathub.flatpakrepo
    flatpak_remote_refs_dir: /github/workspace/flatpak_refs
```

Podman:

1. Create a directory named flatpak_refs
1. Create a file within flatpak_refs with the following content

```plaintext
app/org.videolan.VLC/x86_64/stable
runtime/org.kde.Platform/x86_64/5.15-23.08
```

Run the following command:

```bash
podman run --privileged --volume ./:/github/workspace/ ghcr.io/jasonn3/build-container-installer:main \
          FLATPAK_REMOTE_NAME=flathub \
          FLATPAK_REMOTE_URL=https://flathub.org/repo/flathub.flatpakrepo \
          FLATPAK_REMOTE_REFS="app/org.videolan.VLC/x86_64/stable runtime/org.kde.Platform/x86_64/5.15-23.08"
```
