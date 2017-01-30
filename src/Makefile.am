# Sources for tune

module_DATA = \
  modules/SystemSettings.rb \
  modules/NewID.rb \
  modules/InitHWinfo.rb

client_DATA = \
  clients/system_settings.rb \
  clients/inst_hwinfo.rb \
  clients/hwinfo_proposal.rb \
  clients/hwinfo.rb \
  clients/system_settings_finish.rb

ylibdir = "${yast2dir}/lib/tune"
ylib_DATA = \
  lib/tune/widgets.rb

yncludedir = @yncludedir@/hwinfo
ynclude_DATA = \
  include/hwinfo/system_settings_ui.rb \
  include/hwinfo/newid.rb \
  include/hwinfo/routines.rb \
  include/hwinfo/system_settings_dialogs.rb

scrconf_DATA = \
  scrconf/modprobe_newid.scr

desktop_DATA = \
  desktop/system_settings.desktop \
  desktop/hwinfo.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ylib_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
