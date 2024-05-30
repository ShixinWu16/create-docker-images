# XDMoD Docker Image Generation

The contents of this directory are to be used in generating the various Docker images for use in XDMoD development. A few
examples of typical use will be detailed below.

## Creating Docker images for a new release of XDMoD

1. Update the values in the `.env` file. The new values will be used when naming the new images as defined in the `Image names` section near the bottom of that file.
1. Download the MariaDB RPMs with `./xdmod/get-mariadb-rpms.sh`.
1. Create the images in the correct order, using `docker compose build <image_name>`:
    1. `xdmod-base`.
    1. `xdmod`.
    1. `xdmod-job-performance` and `xdmod-ondemand`.
1. Push each image to the registry using `docker push <image_name>:<tag>`.
1. Tag this `ccr-private-xdmod` Git repo with a tag `<xdmod_github_tag>-<image_release>`, e.g., `v10.5.0-1.0-01`.

## Creating a new Docker image that supports an XDMoD module

This process is much the same as creating images for a new release of XDMoD but with some pre-requisite steps.

1. Create a new subdirectory named after the module, e.g., `xdmod-ondemand`.
1. Add a new Dockerfile to that directory, e.g., `<os>-<module-name>.dockerfile`.
1. Add any supporting files that may be required to successfully build the new image.
  - For instance, `xdmod-job-performance` includes the following:
    - Additional `bin` files that help with handling the mongodb server / data / additional setup that is specific to
      this module.
    - Additional `assets` that include configuration files that determine which version of mongodb to install as well as
      reference data that will be imported into a new installation to provide something to test against.
1. Add a corresponding `service` entry to `docker-compose.yaml` so that it can be interacted with the same as the other
   docker images. 

## Listing Docker images on the registry

List the repositories:
```
curl https://tools-ext-01.ccr.xdmod.org/v2/_catalog
```
For a given repository (e.g., `xdmod-ondemand`), list the tags:
```
curl https://tools-ext-01.ccr.xdmod.org/v2/xdmod-ondemand/tags/list
```
For a given repository (e.g., `xdmod-ondemand`) and tag (`rockylinux8.5-v10.5.0-1.0-01`), list the manifest digest:
```
curl -sS -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -o /dev/null -w '%header{Docker-Content-Digest}' https://tools-ext-01.ccr.xdmod.org/v2/xdmod-ondemand/manifests/x86_64-rockylinux8.5-v10.5.0-1.0-01
```
