%global tag v0.1.0

Name: postgres-xl-ha
Version: 0.1.0
Release: 1

Summary: Postgres-XL resource agents for Pacemaker
License: PostgreSQL
Vendor: Bitnine Global, Inc.
Group: Applications/Databases

BuildArch: noarch

Source: postgres-xl-ha-%{tag}.tar.gz


%description
This package contains two resource agents that manage GTM and coordinator
respectively in a Postgres-XL cluster over Pacemaker.


%prep
%setup -n postgres-xl-ha-%{tag} -q


%install
mkdir -p $RPM_BUILD_ROOT/usr/lib/ocf/resource.d/bitnine
cp -p postgres-xl-coord $RPM_BUILD_ROOT/usr/lib/ocf/resource.d/bitnine
cp -p postgres-xl-gtm $RPM_BUILD_ROOT/usr/lib/ocf/resource.d/bitnine


%files
/usr/lib/ocf/resource.d/bitnine/postgres-xl-coord
/usr/lib/ocf/resource.d/bitnine/postgres-xl-gtm


%changelog
