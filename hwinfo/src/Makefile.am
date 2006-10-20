#
# Makefile.am for tune/hwinfo/src
#

client_DATA = hwinfo.ycp hwinfo_proposal.ycp inst_hwinfo.ycp system_settings.ycp system_settings_finish.ycp

desktop_DATA = hwinfo.desktop system_settings.desktop

yncludedir = @yncludedir@/hwinfo
ynclude_DATA = classnames.ycp routines.ycp newid.ycp system_settings_dialogs.ycp system_settings_ui.ycp

module_DATA = InitHWinfo.ycp NewID.ycp SystemSettings.ycp

hwinfo:
	ln -sf . hwinfo

ycpchook = hwinfo

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(desktop_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common
