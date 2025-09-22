################################################################################
# Board module (before use: export TOKEN=github_pat_....)
################################################################################


PYTHON_BOARD_MODULE_VERSION = main  # or a specific tag/commit hash
PYTHON_BOARD_MODULE_SITE = https://$(TOKEN)@github.com/muzykalegion/board-module.git
PYTHON_BOARD_MODULE_SITE_METHOD = git
PYTHON_BOARD_MODULE_LICENSE = MIT  # change to your license
PYTHON_BOARD_MODULE_LICENSE_FILES = LICENSE

# If the app uses setuptools
#PYTHON_BOARD_MODULE_SETUP_TYPE = setuptools

# Or if you just want to copy files
define PYTHON_BOARD_MODULE_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/opt/board-module
	cp -r $(@D)/* $(TARGET_DIR)/opt/board-module/
endef

$(eval $(python-package))