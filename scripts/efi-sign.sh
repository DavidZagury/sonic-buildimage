#!/bin/sh

set -e

#
# Sign efi file with secret key and certificate
# - shim
# - grub
# - vmlinuz
#
usage() {
    cat <<EOF

$0: Usage
$0 <PRIVATE_KEY_PEM> <CERT_PEM> <EFI_FILE> <EFI_FILE_SIGNED>
Usage example: efi-sign.sh priv-key.pem pub-key.pem shimx64.efi shimx64-signed.efi

EOF
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then 
    usage
fi

PRIVATE_KEY_PEM="$1"
CERT_PEM="$2"
EFI_FILE="$3"
EFI_FILE_SIGNED="$4"


[ -f "$PRIVATE_KEY_PEM" ] || {
    echo "Error: PRIVATE_KEY_PEM file does not exist: $PRIVATE_KEY_PEM"
    usage
    exit 1
}

[ -f "$CERT_PEM" ] || {
    echo "Error: CERT_PEM file does not exist: $CERT_PEM"
    usage
    exit 1
}

[ -f "$EFI_FILE" ] || {
    echo "Error: File for signing does not exist: $EFI_FILE"
    usage
    exit 1
}

if [ -z ${EFI_FILE_SIGNED} ]; then
    echo "ERROR: no arg named <EFI_FILE_SIGNED> supplied"
    usage
    exit 1
fi

echo "$0 signing $EFI_FILE with ${PRIVATE_KEY_PEM},  ${CERT_PEM} to create $EFI_FILE_SIGNED"
sbsign --key ${PRIVATE_KEY_PEM} --cert ${CERT_PEM} \
       --output ${EFI_FILE_SIGNED} ${EFI_FILE} || {
    echo "EFI sign error"
    exit 1
}
