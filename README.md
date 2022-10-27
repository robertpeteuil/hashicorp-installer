# Installer for HashiCorp Binaries

## Automate Download and Installation of HashiCorp binaries

<!-- [![release](https://img.shields.io/github/release/robertpeteuil/hashicorp-installer?colorB=2067b8)](https://github.com/robertpeteuil/hashicorp-installer) -->
[![release](https://img.shields.io/badge/release-1.0.0--beta.2-2067b8)](https://github.com/robertpeteuil/hashicorp-installer)
[![bash](https://img.shields.io/badge/language-bash-89e051.svg?style=flat-square)](https://github.com/robertpeteuil/hashicorp-installer)
[![license](https://img.shields.io/github/license/robertpeteuil/hashicorp-installer?colorB=2067b8)](https://github.com/robertpeteuil/hashicorp-installer)

---

**hashi-install.sh** automates the process of downloading and installing HashiCorp products.  It supports all binaries on releases.hashicorp.com; including terraform, packer, vault, consul, boundary, waypoint, etc..

This script detects host architecture, searches for releases, downloads, verifies and installs binaries.  Optional parameters allow finding latest patch releases, retrieving enterprise binaries, and functioning in special modes.

This is an upgrade and replacement for the earlier projects: [Terraform Installer](https://github.com/robertpeteuil/terraform-installer) and [Packer Installer](https://github.com/robertpeteuil/packer-installer).  It has been designed for easy migration and allows drop-in-replacement with minimal adjustments.

## Usage

```text
hashi-install.sh [-p PRODUCT] [-i VERSION] [-e] [-o] [-h] [-v] [-m] [-a] [-c] [-d]

     -p PRODUCT : product (default='terraform')
     -i VERSION : version to install, supported formats '1.1.9' or '1.1' (default=latest)
     -e         : download enterprise binary when PRODUCT = vault, consul or nomad
     -o         : output only (don't download & install)
     -h         : help
     -v         : display script version

     -m         : Mac - force Intel binary (ignore detection of Apple Silicon)
     -a         : automatically use sudo to install to /usr/local/bin (or $INSTALL_DIR env var)
     -c         : leave binary in current working directory
     -d         : debug output

     PRODUCT may specify abbreviations or full names
       abbreviations: b=boundary, c=consul, n=nomad, p=packer, t=terraform, v=vault, w=waypoint
       full names: https://releases.hashicorp.com
```

### Examples

> specify product with `-p` flag

- defaults to Terraform if `-p` not specified
  - `hashi-install.sh`
- install vault using product abbreviation
  - `hashi-install.sh -p v`
- install consul-template using name
  - `hashi-install.sh -p consul-template`

> specify version with `-i` flag

- install latest - don't specify version
  - `hashi-install.sh`
- install specific version - use MAJOR.MINOR.PATCH format
  - `hashi-install.sh -i 1.1.5`
- determine & install latest patch release - use MAJOR.MINOR format
  - `hashi-install.sh -i 1.1`

### Override CPU detection on Apple Silicon (arm64)

> On macOS hosts with Apple Silicon (arm64)

- by default, if installer detects Apple Silicon it attempts to install `arm64` binaries
- If `arm64` binaries aren't available for a given product + version, it reverts to `amd64` (Intel)
- To override detected CPU and force Intel binaries, use the `-m`
  - ex: when using terraform with an older version of a provider that isn't available for arm64
  - install the intel version of terraform with: `hashi-installer.sh -m`

## Migration from Previous Installers

- macOS on Apple Silicon
  - previous installers assumed `amd64` cpu on macOS
  - This installer will look for `darwin_arm64` binaries when Apple Silicon is detected
  - If `darwin_arm64` binaries aren't available (for a given product/version), it reverts to Intel `darwin_amd64`
  - you can force the old behavior (always use `amd64` binaries), with the `-m` parameter
- installing products other than terraform
  - when replacing a previous installer with this one, add the `-p` parameter specifying the product to install

## Download and Use Locally

Download Installer

``` shell
curl -LO https://raw.github.com/robertpeteuil/hashicorp-installer/master/hashi-install.sh
chmod +x hashi-install.sh
```

## System Requirements

- System with Bash Shell (Linux, macOS, Windows Subsystem for Linux)
- `curl` or `wget` - script will use either one to retrieve metadata and download
- `unzip` - terraform downloads are in zip format

## Disclaimer

I am a HashiCorp employee, but this is a personal project and not officially endorsed or supported by HashiCorp.

## License

Apache 2.0 License - Copyright (c) 2022    Robert Peteuil
