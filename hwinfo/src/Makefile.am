#
# Makefile.am for tune/hwinfo/src
#

client_DATA = hwinfo.ycp hwinfo_proposal.ycp inst_hwinfo.ycp

desktop_DATA = hwinfo.desktop

yncludedir = @yncludedir@/hwinfo
ynclude_DATA = classnames.ycp routines.ycp

module_DATA = InitHWinfo.ycp

hwinfo:
	ln -sf . hwinfo

ycpchook = hwinfo

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(desktop_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common
