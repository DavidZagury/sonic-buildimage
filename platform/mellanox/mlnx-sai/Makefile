.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS += -e

MAIN_TARGET = mlnx-sai_1.mlnx.$(MLNX_SAI_VERSION)_$(CONFIGURED_ARCH).deb
DERIVED_TARGETS = mlnx-sai-dbgsym_1.mlnx.$(MLNX_SAI_VERSION)_$(CONFIGURED_ARCH).deb

# Optional local file path. If set, it will be used instead of downloading from the remote server.
# Note: When using a local SAI file, DOCKER_BUILDER_USER_MOUNT must also be configured to ensure 
# the file is mounted inside the docker build environment.
# DOCKER_BUILDER_USER_MOUNT = /auto/swgwork/maksympr/share/hft/local_releases:/auto/swgwork/maksympr/share/hft/local_releases:rslave
#MLNX_LOCAL_SAI_FILE ?= 
MLNX_LOCAL_SAI_FILE=/auto/swgwork/maksympr/share/hft/local_releases/mlnx-sai.1.mlnx.SAIBuild2412.31.1.4-local.orig.tar.gz
echo "MLNX_LOCAL_SAI_FILE: $(MLNX_LOCAL_SAI_FILE)"
echo "MLNX_SAI_SOURCE_BASE_URL: $(MLNX_SAI_SOURCE_BASE_URL)"
echo "MLNX_SAI_VERSION: $(MLNX_SAI_VERSION)"

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	rm -rf mlnx_sai
	if [ -n "$(MLNX_LOCAL_SAI_FILE)" ] && [ -f "$(MLNX_LOCAL_SAI_FILE)" ]; then
		echo "Using local SAI file: $(MLNX_LOCAL_SAI_FILE)"
		tar -xzf $(MLNX_LOCAL_SAI_FILE)
	else
		echo "Downloading SAI file from remote server"
		wget -c $(MLNX_SAI_SOURCE_BASE_URL)/$(MLNX_SAI_VERSION).tar.gz -O - | tar -xz
	fi
	pushd mlnx_sai

	debuild -e 'make_extra_flags="DEFS=-DACS_OS -DCONFIG_SYSLOG"' -us -uc -d -b
	popd

	mv $(DERIVED_TARGETS) $* $(DEST)/
