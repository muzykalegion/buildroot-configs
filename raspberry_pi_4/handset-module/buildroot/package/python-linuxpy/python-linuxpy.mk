################################################################################
# python-linuxpy Buildroot package
################################################################################

PYTHON_LINUXPY_VERSION = v0.22.0
PYTHON_LINUXPY_SITE = https://github.com/tiagocoutinho/linuxpy.git
PYTHON_LINUXPY_SITE_METHOD = git
PYTHON_LINUXPY_LICENSE = MIT
PYTHON_LINUXPY_LICENSE_FILES = LICENSE

# This tells Buildroot's Python infra to do "pip install ."
PYTHON_LINUXPY_SETUP_TYPE = setuptools

$(eval $(python-package))