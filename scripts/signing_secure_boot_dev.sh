#!/bin/bash
# This script is signing boot components: shim, mmx, grub, kernel and kernel modules in development env.

## Enable debug output for script & exit code when failing occurs 
set -x -e

print_usage() {
    cat <<EOF

$0: Usage
$0 -a <CONFIGURED_ARCH> -r <FS_ROOT> -l <LINUX_KERNEL_VERSION> -c <PEM_CERT> -p <PEM_PRIV_KEY>

EOF
}

clean_file() {
    if [ -f $1 ]; then
        echo "clean old file named: $1"
        echo "sudo rm -f $1"
        sudo sudo rm -f $1
    fi
}

while getopts 'a:r:l:c:p:hv' flag; do
  case "${flag}" in
    a) CONFIGURED_ARCH="${OPTARG}" ;;
    r) FS_ROOT="${OPTARG}" ;;
    l) LINUX_KERNEL_VERSION="${OPTARG}" ;;
    c) PEM_CERT="${OPTARG}" ;;
    p) PEM_PRIV_KEY="${OPTARG}" ;;
    v) VERBOSE='true' ;;
    h) print_usage
       exit 1 ;;
  esac
done
if [ $OPTIND -eq 1 ]; then echo "no options were pass"; print_usage; exit 1 ;fi

echo "$0 signing & verifying EFI files and Kernel Modules start ..."

if [ -z ${CONFIGURED_ARCH} ]; then
    echo "ERROR: CONFIGURED_ARCH=${CONFIGURED_ARCH} is empty"
    usage
    exit 1
fi

if [ -z ${FS_ROOT} ]; then
    echo "ERROR: FS_ROOT=${FS_ROOT} is empty"
    usage
    exit 1
fi

if [ -z ${LINUX_KERNEL_VERSION} ]; then
    echo "ERROR: LINUX_KERNEL_VERSION=${LINUX_KERNEL_VERSION} is empty"
    usage
    exit 1
fi

if [ ! -f "${PEM_CERT}" ]; then
    echo "ERROR: PEM_CERT=${PEM_CERT} file does not exist"
    usage
    exit 1
fi

if [ ! -f "${PEM_PRIV_KEY}" ]; then
    echo "ERROR: PEM_PRIV_KEY=${PEM_PRIV_KEY} file does not exist"
    usage
    exit 1
fi

ARCH=''
if [[ $CONFIGURED_ARCH == amd64 ]]; then
ARCH=x86_64
EFI_ARCH=x64
fi

# efi-sign.sh is used to sign: shim, mmx, grub, and kernel (vmlinuz)
EFI_SIGNING=scripts/efi-sign.sh

######################
## shim & mmx signing
######################

# shim dirs
SHIM_DIR_SRC=$FS_ROOT/usr/lib/shim
MMX_EFI_SRC=$SHIM_DIR_SRC/mm${EFI_ARCH}.efi
SHIMX_EFI_SRC=$SHIM_DIR_SRC/shim${EFI_ARCH}.efi

# clean old files
clean_file ${SHIMX_EFI_SRC}-signed
clean_file ${MMX_EFI_SRC}-signed
clean_file $FS_ROOT/boot/shim${EFI_ARCH}.efi
clean_file $FS_ROOT/boot/mm${EFI_ARCH}.efi

echo "signing shim${EFI_ARCH}.efi & mm${EFI_ARCH}.efi from location: ${SHIM_DIR_SRC} .."
sudo ${EFI_SIGNING} -p $PEM_PRIV_KEY -c $PEM_CERT -e ${SHIMX_EFI_SRC} -s ${SHIMX_EFI_SRC}-signed
sudo ${EFI_SIGNING} -p $PEM_PRIV_KEY -c $PEM_CERT -e ${MMX_EFI_SRC} -s ${MMX_EFI_SRC}-signed

# cp shim & mmx signed files to boot directory in the fs.
sudo cp ${SHIMX_EFI_SRC}-signed $FS_ROOT/boot/shim${EFI_ARCH}.efi
sudo cp ${MMX_EFI_SRC}-signed $FS_ROOT/boot/mm${EFI_ARCH}.efi

# verifying signature of mm & shim efi files.
sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e $FS_ROOT/boot/shim${EFI_ARCH}.efi  
sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e $FS_ROOT/boot/mm${EFI_ARCH}.efi

######################
## grub signing
######################

GRUB_DIR_SRC=$FS_ROOT/usr/lib/grub/x86_64-efi/monolithic/
GRUB_EFI_SRC=$GRUB_DIR_SRC/grub${EFI_ARCH}.efi

# clean old files
clean_file ${GRUB_EFI_SRC}-signed
clean_file $FS_ROOT/boot/grub${EFI_ARCH}.efi

echo "signing grub${EFI_ARCH}.efi from location: ${GRUB_EFI_SRC} .."
sudo ${EFI_SIGNING} -p $PEM_PRIV_KEY -c $PEM_CERT -e ${GRUB_EFI_SRC} -s ${GRUB_EFI_SRC}-signed

# cp signed grub to fs boot dir.
sudo cp ${GRUB_EFI_SRC}-signed $FS_ROOT/boot/grub${EFI_ARCH}.efi

# verifying signature of grub efi file.
sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e $FS_ROOT/boot/grub${EFI_ARCH}.efi

######################
## vmlinuz signing
######################

CURR_VMLINUZ=$FS_ROOT/boot/vmlinuz-${LINUX_KERNEL_VERSION}-${CONFIGURED_ARCH}

# clean old files
clean_file ${CURR_VMLINUZ}-signed

echo "signing ${CURR_VMLINUZ} .."
sudo ${EFI_SIGNING} -p $PEM_PRIV_KEY -c $PEM_CERT -e ${CURR_VMLINUZ} -s ${CURR_VMLINUZ}-signed

# rename signed vmlinuz with the name vmlinuz without signed suffix
sudo mv ${CURR_VMLINUZ}-signed ${CURR_VMLINUZ}

sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e ${CURR_VMLINUZ}

#########################
# Kernel Modules signing
#########################
sudo bash scripts/signing_kernel_modules.sh -l $LINUX_KERNEL_VERSION -c ${PEM_CERT} -p ${PEM_PRIV_KEY} -k ${FS_ROOT}

echo "$0 signing & verifying EFI files and Kernel Modules DONE"
