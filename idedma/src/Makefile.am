#
# Makefile.am for tune/idedma/src
#

yncludedir = @yncludedir@/idedma

client_DATA =			\
	idedma.ycp		\
	idedma_auto.ycp		\
	idedma_summary.ycp	\
	idedma_write.ycp

ynclude_DATA =			\
	helps.ycp		\
	cmdline.ycp		\
	ui.ycp

# exclude IDE DMA from Y2CC on s390
if !ARCH_S390
desktop_DATA =			\
	idedma.desktop
endif

module_DATA =			\
	Idedma.ycp

hwinfo:
	ln -sf ../../hwinfo/src hwinfo

ycpchook = hwinfo

YCPCFLAGS=-I.


EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
