#
# spec file for package yast2-tune
#
# Copyright (c) 2015 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-tune
Version:        3.1.9
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.1.10
# hwinfo/classnames.ycp
# Wizard::SetDesktopTitleAndIcon
Requires:       yast2 >= 2.21.22
Requires:       yast2-bootloader

Provides:       yast2-config-hwinfo
Provides:       yast2-trans-tune
Provides:       yast2-tune-idedma
Obsoletes:      yast2-config-hwinfo
Obsoletes:      yast2-trans-tune
Obsoletes:      yast2-tune-idedma
Provides:       y2c_tune
Provides:       y2t_tune
Provides:       yast2-config-tune
Provides:       yast2-trans-hwinfo
Provides:       yast2-trans-idedma
Obsoletes:      y2c_tune
Obsoletes:      y2t_tune
Obsoletes:      yast2-config-tune
Obsoletes:      yast2-trans-hwinfo
Obsoletes:      yast2-trans-idedma
Obsoletes:      yast2-tune-devel-doc

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        YaST2 - Hardware Tuning
License:        GPL-2.0+
Group:          System/YaST

%description
This package contains the YaST2 component for hardware configuration.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

%post
# rename the config file to the new modprobe schema
if test -e /etc/modprobe.d/newid; then
    mv -f /etc/modprobe.d/newid /etc/modprobe.d/50-newid.conf
fi

%files
%defattr(-,root,root)
%dir %{_datadir}/appdata
%{_datadir}/appdata/%{name}.metainfo.xml
%{yast_yncludedir}/hwinfo/*
%{yast_clientdir}/*.rb
%{yast_desktopdir}/hwinfo.desktop
%{yast_desktopdir}/system_settings.desktop
%{yast_moduledir}/*.rb
%{yast_scrconfdir}/*.scr
%dir %{yast_docdir}
%doc %{yast_docdir}/COPYING

%changelog
