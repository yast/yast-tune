#
# Makefile.am for idedma/src
#
# $Id$
#

yncludedir = @yncludedir@/idedma

client_DATA =			\
	idedma.ycp		\
	idedma_auto.ycp		\
	idedma_summary.ycp	\
	idedma_write.ycp

ynclude_DATA =			\
	helps.ycp		\
	ui.ycp

# exclude IDE DMA from Y2CC on s390
if !ARCH_S390
config_DATA =			\
	idedma.y2cc
endif

module_DATA =			\
	Idedma.ycp

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(config_DATA) $(module_DATA)
