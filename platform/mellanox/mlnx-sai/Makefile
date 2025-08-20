.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS += -e

MAIN_TARGET = mlnx-sai_1.mlnx.$(MLNX_SAI_VERSION)_$(CONFIGURED_ARCH).deb
DERIVED_TARGETS = mlnx-sai-dbgsym_1.mlnx.$(MLNX_SAI_VERSION)_$(CONFIGURED_ARCH).deb

# Define debuild flags for easy maintenance
DEFS_BASE = -DACS_OS -DCONFIG_SYSLOG
DEFS_PLD = 

ifeq ($(PLD_BUILD),true)
DEFS_PLD = -DENABLE_PLD=1
endif

DEBUILD_FLAGS = 'make_extra_flags="DEFS=$(DEFS_BASE) $(DEFS_PLD)"'

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	rm -rf mlnx_sai
	wget -c $(MLNX_SAI_SOURCE_BASE_URL)/$(MLNX_SAI_VERSION).tar.gz -O - | tar -xz
	pushd mlnx_sai

	debuild -e $(DEBUILD_FLAGS) -us -uc -d -b
	popd

	mv $(DERIVED_TARGETS) $* $(DEST)/
