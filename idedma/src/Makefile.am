#
# Makefile.am for y2c_idedma/src
#
# $Id$
#

clientsdir = $(YAST2DIR)/clients
yncludedir = $(YAST2DIR)/include/idedma
menudir = $(YAST2DIR)/menuentries
modulesdir = $(YAST2DIR)/modules

clients_DATA =			\
	idedma.ycp		\
	idedma_auto.ycp	\
	idedma_summary.ycp	\
	idedma_write.ycp

ynclude_DATA =			\
	helps.ycp		\
	ui.ycp

menu_DATA =			\
	menuentry_idedma.y2cc

modules_DATA =			\
	Idedma.ycp

EXTRA_DIST = $(clients_DATA) $(ynclude_DATA) $(menu_DATA) $(modules_DATA)
