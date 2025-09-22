################################################################################
#
# yamspy
#
################################################################################

YAMSPY_VERSION = master
YAMSPY_SITE = https://github.com/thecognifly/YAMSPy.git
YAMSPY_SITE_METHOD = git
YAMSPY_SITE_BRANCH = master
YAMSPY_SETUP_TYPE = setuptools
YAMSPY_DEPENDENCIES = python3 python-serial host-python-serial
YAMSPY_LICENSE = MIT
YAMSPY_LICENSE_FILES = LICENSE

$(eval $(python-package))
