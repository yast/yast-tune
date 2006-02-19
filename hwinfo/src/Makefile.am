#
# Makefile.am for tune/hwinfo/src
#

client_DATA = hwinfo.ycp hwinfo_proposal.ycp inst_hwinfo.ycp pci_id.ycp

if ARCH_S390

desktop_DATA = hwinfo.desktop

else

desktop_DATA = hwinfo.desktop pci_id.desktop

endif

yncludedir = @yncludedir@/hwinfo
ynclude_DATA = classnames.ycp routines.ycp newid.ycp

module_DATA = InitHWinfo.ycp NewID.ycp

hwinfo:
	ln -sf . hwinfo

ycpchook = hwinfo

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(desktop_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common
