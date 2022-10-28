#!/usr/bin/env bash

set -e

# HASHICORP INSTALL - Automated Install of HashiCorp Products
#   Apache 2 License - Copyright (c) 2022  Robert Peteuil  @RobertPeteuil
#
#     Automatically Download, Extract and Install HashiCorp binaries
#        Version Detection - Most Recent, Latest Point Release or Specific Version
#
#   from: https://github.com/robertpeteuil/hashicorp-installer

# Uncomment line below to always use 'sudo' to install to /usr/local/bin/
# sudoInstall=true
defaultProduct="terraform"

scriptname="hcinstall"
scriptbuildnum="1.0.0-beta.4"
scriptbuilddate="2022-10-27"

# CHECK DEPENDANCIES AND SET NET RETRIEVAL TOOL
if ! unzip -h 2&> /dev/null; then
  echo "error: 'unzip' not installed and required"
  exit 1
fi

if curl -h 2&> /dev/null; then
  nettool="curl"
elif wget -h 2&> /dev/null; then
  nettool="wget"
else
  echo "error: neither 'wget' nor 'curl' are installed (one required)"
  exit 1
fi

displayVer() {
  echo -e "${scriptname} ver ${scriptbuildnum} - ${scriptbuilddate}"
}

usage() {
  [[ "$1" ]] && echo -e "Download and Install HashiCorp products\n"
  echo -e "usage: ${scriptname} [-p PRODUCT] [-i VERSION] [-e] [-o] [-h] [-v] [-m] [-a] [-c] [-d]"
  echo
  echo -e "     -p PRODUCT\t: product (default='terraform')"
  echo -e "     -i VERSION\t: version to install, supported formats '1.1.9' or '1.1' (default=latest)"
  echo -e "     -e\t\t: download enterprise binary when PRODUCT = vault, consul or nomad"
  echo -e "     -o\t\t: output only (don't download & install)"
  echo -e "     -h\t\t: help"
  echo -e "     -v\t\t: display script version"
  echo
  echo -e "     -m\t\t: Mac - force Intel binary (ignore detection of Apple Silicon)"
  echo -e "     -a\t\t: automatically use sudo to install to /usr/local/bin (or \$INSTALL_DIR env var)"
  echo -e "     -c\t\t: leave binary in current working directory"
  echo -e "     -d\t\t: debug output"
  echo
  echo -e "     PRODUCT may specify product name or abbreviation"
  echo -e "       product names : https://releases.hashicorp.com"
  echo -e "       abbreviations : b=boundary, c=consul, n=nomad, p=packer, t=terraform, v=vault, w=waypoint"
}

mostRecent() {
  case "${nettool}" in
    curl)
      LATEST=$(curl -sS https://api.releases.hashicorp.com/v1/releases/${1}/latest 2>/dev/null | grep -o '"version":"[^"]*' | grep -o '[^"]*$')
      ;;
    wget)
      LATEST=$(wget -q -O- https://api.releases.hashicorp.com/v1/releases/${1}/latest 2>/dev/null | grep -o '"version":"[^"]*' | grep -o '[^"]*$')
      ;;
  esac
  echo -n "$LATEST"
}

# get latest point release for given version, ex: Vault 1.8 = 1.8.12
latestRelease() {
  i=0
  while :
  do
    INCVER="${VERSION}.${i}"
    case "${nettool}" in
      curl)
        VERCHECK=$(curl -o /dev/null --silent --write-out '%{http_code}\n' https://api.releases.hashicorp.com/v1/releases/${PRODUCT}/${INCVER})
        ;;
      wget)
        VERCHECK=$(wget -O /dev/null -S https://api.releases.hashicorp.com/v1/releases/${PRODUCT}/${INCVER} 2>&1 | grep "HTTP/" | awk '{print $2}')
        ;;
    esac
    if [[ $VERCHECK == 200 ]]; then
      LATESTREL="$INCVER"
    else
      break
    fi
    i=$((i+1))
  done
  echo -n "$LATESTREL"
}

createLinks() {
  FILENAME="${PRODUCT}_${VERSION}${ENTPREFIX}_${OS}_${PROC}.zip"
  LINK="https://releases.hashicorp.com/${PRODUCT}/${VERSION}${ENTPREFIX}/${FILENAME}"
  SHALINK="https://releases.hashicorp.com/${PRODUCT}/${VERSION}${ENTPREFIX}/${PRODUCT}_${VERSION}${ENTPREFIX}_SHA256SUMS"

  case "${nettool}" in
    wget*)
      LINKVALID=$(wget --spider -S "$LINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
      SHALINKVALID=$(wget --spider -S "$SHALINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
      ;;
    curl*)
      LINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$LINK")
      SHALINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$SHALINK")
      ;;
  esac
}

displayValues() {
  echo -e " PRODUCT:\t$PRODUCT"
  [[ "$ENTAVAIL" ]] && echo -e " ENTERPRISE:\ttrue"
  echo -e " VER:\t\t$VERSION"
  echo -e " OS:\t\t$OS"
  echo -e " PROC:\t\t$PROC"
  echo -e " URL:\t\t$LINK"
}

verifyLinks() {
  if [[ "$LINKVALID" != 200 ]]; then
    echo -e "error: cannot install - download URL invalid\n"
    displayValues
    exit 1
  fi

  if [[ "$SHALINKVALID" != 200 ]]; then
    echo -e "error: cannot install - URL for SHA checksum invalid\n"
    displayValues
    echo -e " SHA URL:\t${SHALINK}\n"
    exit 1
  fi

  if [[ -n "$DEBUG" ]]; then
    echo
    displayValues
    echo -e " SHA URL:\t${SHALINK}\n"
  fi
}

isIn() {
  [[ "$2" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]] && echo 1 || echo 0
}

while getopts ":i:acdehmop:v" arg; do
  case "${arg}" in
    a)  sudoInstall=true;;
    c)  cwdInstall=true;;
    d)  DEBUG=true;;
    i)  VERSION=${OPTARG};;
    e)  ENTDL=true;;
    h)  usage x; exit;;
    m)  M1OVERIDE=true;;
    o)  OUTPUTONLY=true;;
    p)  PROD=${OPTARG};;
    v)  displayVer; exit;;
    \?) echo -e "error: invalid option: $OPTARG\n"; usage; exit;;
    :)  echo -e "error: -$OPTARG requires an argument\n"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))


#### PROCESS OPTIONS

# SET PRODUCT NAME
if [[ -z "${PROD}" ]]; then
  PRODUCT="$defaultProduct"
else
  case "${PROD}" in
    b) PRODUCT="boundary" ;;
    c) PRODUCT="consul" ;;
    n) PRODUCT="nomad" ;;
    p) PRODUCT="packer" ;;
    t) PRODUCT="terraform" ;;
    v) PRODUCT="vault" ;;
    w) PRODUCT="waypoint" ;;
    *) PRODUCT="${PROD}" ;;
  esac
fi

# Capitalize Product Name (for display)
DPRODUCT="$(tr '[:lower:]' '[:upper:]' <<< ${PRODUCT:0:1})${PRODUCT:1}"

# DETERMINE VERSION
if [ $(echo $VERSION | tr -d -c '.' | wc -c) == 1 ]; then  # partial version
  [[ "$DEBUG" ]] && echo "debug: partial version specified finding latest of $PRODUCT $VERSION"
  POINTRELEASE=$(latestRelease)
  # VERSIONTEXT="Latest release for ${PRODUCT}-${VERSION} is ${POINTRELEASE}"
  [[ "$DEBUG" || "$OUTPUTONLY" ]] && echo "Latest release for ${PRODUCT}-${VERSION} is ${POINTRELEASE}"
  VERSION="$POINTRELEASE"
# else find most recent
elif [[ -z "$VERSION" ]]; then
  [[ "$DEBUG" ]] && echo "Find most recent"
  VERSION=$(mostRecent "${PRODUCT}")
  if [[ -z "$VERSION" ]]; then
    echo "error: product \"${PRODUCT}\" not found in HashiCorp releases"
    exit 1
  fi
  [[ "$OUTPUTONLY" ]] && echo "info: latest ${PRODUCT} release is ${VERSION}"
fi

# exit if output only
[[ "$OUTPUTONLY" ]] && exit 0

# DETERMINE OS AND PROCESSOR
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "linux" ]]; then
  PROC=$(lscpu 2> /dev/null | awk '/Architecture/ {if($2 == "x86_64") {print "amd64"; exit} else if($2 ~ /arm/) {print "arm"; exit} else if($2 ~ /aarch64/) {print "arm64"; exit} else {print "386"; exit}}')
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/model\ name/ {if($0 ~ /ARM/) {print "arm"; exit}}')
  fi
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/flags/ {if($0 ~ /lm/) {print "amd64"; exit} else {print "386"; exit}}')
  fi
elif [[ "$OS" == "darwin" && "$M1OVERIDE" ]]; then
  [[ "$DEBUG" ]] && echo "debug: Mac Intel binary forced"
  PROC="amd64"
elif [[ "$OS" == "darwin" ]]; then
  CPU=$(sysctl -n machdep.cpu.brand_string | cut -c1)
  if [[ "$CPU" == "A" ]]; then
    [[ "$DEBUG" ]] && echo "debug: Apple silicon CPU found (arm64)"
    PROC="arm64"
  else
    PROC="amd64"
  fi
fi

# CHECK FOR ENTERPRISE
if [[ "$ENTDL" ]]; then
  if [[ $(isIn "$PRODUCT" "consul vault nomad") == 1 ]]; then
    ENTAVAIL=true
    ENTPREFIX="+ent"
    ENTTEXT=" Enterprise"
    [[ "$DEBUG" ]] && echo "debug: enterprise binary specified"
  else
    unset ENTAVAIL
    unset ENTPREFIX
    unset ENTTEXT
    echo "warning: enterprise version requested, but not available for ${PRODUCT} v${VERSION}"
    echo -e "\t downloading OSS version instead\n"
  fi
fi

# CREATE FILENAME AND LINKS
createLinks

# CHECK AND ADJUST FOR ARM64 INVALID LINKS
if [[ "$SHALINKVALID" == 200 && "$LINKVALID" != 200 ]]; then
  # enterprise build for product version, but not for the detected platform + cpu
  if [[ "$OS" == "darwin" && "$PROC" == "arm64" ]]; then
    # macOS - Apple Silicon (arm64) CPU binary invalid, switch to Intel (amd64) CPU
    echo -e "warning: ${PRODUCT} v${VERSION} for ${OS} has no ${PROC} build, switching to amd64\n"
    PROC="amd64"
    createLinks
  elif [[ "$OS" == "linux" && "$PROC" == "arm64" ]]; then
    # linux - URL for arm64 binary invalid, switch to arm
    echo -e "warning: ${PRODUCT} v${VERSION} for ${OS} has no ${PROC} build, switching to arm\n"
    PROC="arm"
    createLinks
  fi
fi

# VERIFY LINKS
verifyLinks

#### EXECUTION

# DEFAULT TO TERRAFORM (backward compatability with terraform-installer)
if [[ "$PRODUCT" == "terraform" ]] && [[ -n "$TF_INSTALL_DIR" ]]; then
  INSTALL_DIR="$TF_INSTALL_DIR"
fi

# DETERMINE DESTINATION
if [[ "$cwdInstall" ]]; then
  BINDIR=$(pwd)
elif [[ -n "$INSTALL_DIR" ]]; then
  BINDIR="$INSTALL_DIR"
  CMDPREFIX="${sudoInstall:+sudo }"
  STREAMLINED=true
elif [[ -w "/usr/local/bin" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX=""
  STREAMLINED=true
elif [[ "$sudoInstall" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX="sudo "
  STREAMLINED=true
else
  echo -e "HashiCorp Installer\n"
  echo "Specify install directory for ${DPRODUCT}${ENTTEXT} ${VERSION} (a,b or c):"
  echo -en "\t(a) '~/bin'    (b) '/usr/local/bin' as root    (c) abort : "
  read -r -n 1 SELECTION
  echo
  if [ "${SELECTION}" == "a" ] || [ "${SELECTION}" == "A" ]; then
    BINDIR="${HOME}/bin"
    CMDPREFIX=""
  elif [ "${SELECTION}" == "b" ] || [ "${SELECTION}" == "B" ]; then
    BINDIR="/usr/local/bin"
    CMDPREFIX="sudo "
  else
    exit 0
  fi
fi

# CREATE TMPDIR FOR EXTRACTION
if [[ ! "$cwdInstall" ]]; then
  TMPDIR=${TMPDIR:-/tmp}
  UTILTMPDIR="${PRODUCT}_${VERSION}"

  cd "$TMPDIR" || exit 1
  mkdir -p "$UTILTMPDIR"
  cd "$UTILTMPDIR" || exit 1
fi

# DOWNLOAD ZIP AND CHECKSUM FILES
case "${nettool}" in
  wget*)
    wget -q "$LINK" -O "$FILENAME"
    wget -q "$SHALINK" -O SHAFILE
    ;;
  curl*)
    curl -s -o "$FILENAME" "$LINK"
    curl -s -o SHAFILE "$SHALINK"
    ;;
esac

# VERIFY ZIP CHECKSUM
if shasum -h 2&> /dev/null; then
  expected_sha=$(cat SHAFILE | grep "$FILENAME" | awk '{print $1}')
  download_sha=$(shasum -a 256 "$FILENAME" | cut -d' ' -f1)
  if [ $expected_sha != $download_sha ]; then
    echo "error: download checksum incorrect"
    echo " expected: $expected_sha"
    echo " actual: $download_sha"
    exit 1
  fi
fi

# EXTRACT ZIP
unzip -qq "$FILENAME" || exit 1

# COPY TO DESTINATION
if [[ ! "$cwdInstall" ]]; then
  mkdir -p "${BINDIR}" || exit 1
  ${CMDPREFIX} mv "${PRODUCT}" "$BINDIR" || exit 1
  # CLEANUP AND EXIT
  cd "${TMPDIR}" || exit 1
  rm -rf "${UTILTMPDIR}"
  [[ ! "$STREAMLINED" ]] && echo
  # echo "${PRODUCT}${ENTTEXT} Version ${VERSION} installed to ${BINDIR}"
  echo "${DPRODUCT}${ENTTEXT} version ${VERSION} installed to ${BINDIR}"
else
  rm -f "$FILENAME" SHAFILE
  # echo "${PRODUCT}${ENTTEXT} Version ${VERSION} downloaded"
  echo "${DPRODUCT}${ENTTEXT} version ${VERSION} downloaded"
fi

exit 0
