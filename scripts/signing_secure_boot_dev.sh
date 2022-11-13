#!/bin/bash
# This script is signing boot components: shim, mmx, grub, kernel and kernel modules in development env.

## Enable debug output for script & exit code when failing occurs 
set -x -e

usage() {
    cat <<EOF

$0: Usage
$0 <CONFIGURED_ARCH> <FS_ROOT> <LINUX_KERNEL_VERSION> <PEM_CERT> <PEM_PRIV_KEY>
Usage example: efi-sign.sh priv-key.pem pub-key.pem shimx64.efi shimx64-signed.efi

EOF
}

clean_file() {
    if [ -f $1 ]; then
        echo "clean old file named: $1"
        echo "sudo rm $1"
        sudo rm $1
        echo "$?"
        exit 1
    fi
}

echo "$0 signing & verifying EFI files and Kernel Modules start ..."
CONFIGURED_ARCH="$1"
FS_ROOT="$2"
LINUX_KERNEL_VERSION="$3"
PEM_CERT="$4"
PEM_PRIV_KEY="$5"

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

# clean old shim & mmx files in the env
sudo rm -f ${SHIMX_EFI_SRC}-signed ${MMX_EFI_SRC}-signed \
           $FS_ROOT/boot/shim${EFI_ARCH}.efi $FS_ROOT/boot/mm${EFI_ARCH}.efi

echo "signing shim${EFI_ARCH}.efi & mm${EFI_ARCH}.efi from location: ${SHIM_DIR_SRC} .."
sudo ${EFI_SIGNING} $PEM_PRIV_KEY $PEM_CERT ${SHIMX_EFI_SRC} ${SHIMX_EFI_SRC}-signed
sudo ${EFI_SIGNING} $PEM_PRIV_KEY $PEM_CERT ${MMX_EFI_SRC} ${MMX_EFI_SRC}-signed

# cp shim & mmx signed files to boot directory in the fs.
sudo cp ${SHIMX_EFI_SRC}-signed $FS_ROOT/boot/shim${EFI_ARCH}.efi
sudo cp ${MMX_EFI_SRC}-signed $FS_ROOT/boot/mm${EFI_ARCH}.efi

# verifying signature of mm & shim efi files.
sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e $FS_ROOT/boot/shim${EFI_ARCH}.efi  
sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e $FS_ROOT/boot/mm${EFI_ARCH}.efi

######################
## grub signing
######################

# Make a config grub file that reads a grub.cfg from the EFI directory
# where the final grub binary is running.
tmp_config=$(mktemp)
cat <<EOF > $tmp_config
configfile \$cmdpath/grub.cfg
EOF

# clean old files
clean_file $FS_ROOT/boot/grub.cfg
clean_file ${GRUB_EFI_SRC}-signed
clean_file $FS_ROOT/boot/grub${EFI_ARCH}.efi

sudo cp $tmp_config $FS_ROOT/boot/grub.cfg

GRUB_DIR_SRC=$FS_ROOT/usr/lib/grub/x86_64-efi/monolithic/
GRUB_EFI_SRC=$GRUB_DIR_SRC/grub${EFI_ARCH}.efi

# clean old grub files in the env
sudo rm -f ${GRUB_EFI_SRC}-signed $FS_ROOT/boot/grub${EFI_ARCH}.efi

echo "signing grub${EFI_ARCH}.efi from location: ${GRUB_EFI_SRC} .."
sudo ${EFI_SIGNING} $PEM_PRIV_KEY $PEM_CERT ${GRUB_EFI_SRC} ${GRUB_EFI_SRC}-signed

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

# clean old grub files in the env
sudo rm -f ${CURR_VMLINUZ}-signed

echo "signing ${CURR_VMLINUZ} .."
sudo ${EFI_SIGNING} $PEM_PRIV_KEY $PEM_CERT ${CURR_VMLINUZ} ${CURR_VMLINUZ}-signed

# rename signed vmlinuz with the name vmlinuz without signed suffix
sudo cp ${CURR_VMLINUZ}-signed ${CURR_VMLINUZ}

sudo bash scripts/secure_boot_signature_verification.sh -c $PEM_CERT -e ${CURR_VMLINUZ}

#########################
# Kernel Modules signing
#########################
sudo bash scripts/signing_kernel_modules.sh $LINUX_KERNEL_VERSION ${PEM_CERT} ${PEM_PRIV_KEY}

echo "$0 signing & verifying EFI files and Kernel Modules DONE"