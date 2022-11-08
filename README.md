# Installer for HashiCorp Binaries

## Automate Download and Installation of HashiCorp binaries

[![release](https://img.shields.io/github/release/robertpeteuil/hashicorp-installer?colorB=2067b8)](https://github.com/robertpeteuil/hashicorp-installer)
[![bash](https://img.shields.io/badge/language-bash-89e051.svg?style=flat-square)](https://github.com/robertpeteuil/hashicorp-installer)
[![license](https://img.shields.io/github/license/robertpeteuil/hashicorp-installer?colorB=2067b8)](https://github.com/robertpeteuil/hashicorp-installer)

---

**hcinstall** automates the process of downloading and installing HashiCorp products.  It supports all binaries on [releases.hashicorp.com](https://releases.hashicorp.com); including [terraform](https://www.terraform.io/), [packer](https://www.packer.io/), [vault](https://www.vaultproject.io/), [consul](https://www.consul.io/), [boundary](https://www.boundaryproject.io/), [waypoint](https://www.waypointproject.io/), etc..

This script searches releases, determines correct binary for the system, downloads binary and installs it to the selected location.  It allows install of the most recent version of any product with only one parameter. There are many optional parameters which allow it to be used to query/validate version numbers, retrieve enterprise binaries, and specifying custom location for the downloaded binary.

Example, display the latest patch release for terraform 1.1: `hcinstall -i 1.1 -o`

This is an upgrade and replacement for the earlier projects: [Terraform Installer](https://github.com/robertpeteuil/terraform-installer) and [Packer Installer](https://github.com/robertpeteuil/packer-installer).  It has been designed for easy migration and allows drop-in-replacement with minimal adjustments.

## Use

```text
hcinstall [-p PRODUCT] [-i VERSION] [-e] [-o] [-h] [-v] [-m] [-a] [-c] [-d]

     -p PRODUCT : product (default='terraform')
     -i VERSION : version (default=latest)
                  specify either product version (ex: '1.1') or specific release (ex: '1.1.9')
     -e         : download enterprise binary for PRODUCT = vault, consul or nomad
     -o         : only output release info (don't download, install)
     -h         : help
     -v         : display script version

     -m         : Mac - force Intel binary (ignore detection of Apple Silicon)
     -a         : automatically use sudo to install to /usr/local/bin (or $INSTALL_DIR env var)
     -c         : leave binary in current working directory
     -d         : debug output

     PRODUCT may specify product name or abbreviation
       product names : https://releases.hashicorp.com
       abbreviations : b=boundary, c=consul, n=nomad, p=packer, t=terraform, v=vault, w=waypoint
```

## Download

Download latest release from my bootstrap server (iac.sh or https://iac.sh)

``` shell
curl iac.sh/hcinstall > hcinstall
chmod +x hcinstall
# optional - move to system binary directory
sudo mv hcinstall /usr/local/bin
```

Download from GitHub

``` shell
curl -LO https://raw.github.com/robertpeteuil/hashicorp-installer/master/hcinstall
chmod +x hcinstall
```

## Parameters

### Specifying Products `-p`

- `-p` not specified, defaults to Terraform
  - `hcinstall`
- specify product abbreviation (v = vault)
  - `hcinstall -p v`
- specify full binary name
  - `hcinstall -p consul-template`

### Specifying Specific or Partial Versions `-i`

- latest - don't specify `-i`
  - `hcinstall`
- specific version - use MAJOR.MINOR.PATCH format
  - `hcinstall -i 1.1.5`
- latest patch release - use MAJOR.MINOR format
  - `hcinstall -i 1.1`

### Output Only Mode `-o`

> find latest version or patch release, display info and exit without install

- display latest version of Terraform
  - `hcinstall -o`
- display latest patch release for Vault 1.9
  - `hcinstall -p v -i 1.9 -o`

## Override arm64 binaries on macOS `-m`

- If installer detects Apple Silicon it attempts to install `arm64` binaries
- If `arm64` binaries aren't available for a given product + version, it reverts to `amd64` (Intel)
- Force install of Intel binaries with `-m` flag
  - Useful for Terraform when using use older provider versions that lack an `arm64` build
    - the terraform binary and provider binary need to share the same cpu architecture

## Release Info

### Migration from Previous Installers

- macOS on Apple Silicon
  - behavior change from previous scripts when running on Apple Silicon Macs
    - installer looks for `darwin_arm64` binaries when Apple Silicon is detected
    - previous installers assumed `amd64` cpu on macOS
  - force old behavior (always use `amd64` binaries), with the `-m` parameter
- installing products other than terraform
  - use `-p` parameter specifying the product to install

### System Requirements

- System with Bash Shell (Linux, macOS, Windows Subsystem for Linux)
- `curl` or `wget` - script will use either one to retrieve metadata and download
- `unzip` - terraform downloads are in zip format

## Disclaimer

I am a HashiCorp employee, but this is a personal project and not officially endorsed or supported by HashiCorp.

## License

Apache 2.0 License - Copyright (c) 2022  Robert Peteuil
