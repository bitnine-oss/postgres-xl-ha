#!/usr/bin/perl
# This program is open source, licensed under the PostgreSQL License.
# For license terms, see the LICENSE file.
#
# Copyright (C) 2016: Jehan-Guillaume de Rorthais and Mael Rimbault

=head1 NAME

OCF_Directories - Binaries and binary options for use in Resource Agents

=head1 SYNOPSIS

  use FindBin;
  use lib "$FindBin::RealBin/../../lib/heartbeat/";
  
  use OCF_Directories;

=head1 DESCRIPTION

This module has been ported from the ocf-directories shell script of the
resource-agents project. See L<https://github.com/ClusterLabs/resource-agents/>.

=head1 VARIABLES

Here are the variables exported by this module:

=over

=item $INITDIR

=item $HA_DIR

=item $HA_RCDIR

=item $HA_CONFDIR

=item $HA_CF

=item $HA_VARLIB

=item $HA_RSCTMP

=item $HA_RSCTMP_OLD

=item $HA_FIFO

=item $HA_BIN

=item $HA_SBIN_DIR

=item $HA_DATEFMT

=item $HA_DEBUGLOG

=item $HA_RESOURCEDIR

=item $HA_DOCDIR

=item $__SCRIPT_NAME

=item $HA_VARRUN

=item $HA_VARLOCK

=item $ocf_prefix

=item $ocf_exec_prefix

=back

=cut

package OCF_Directories;

use strict;
use warnings;
use 5.008;
use File::Basename;

BEGIN {
    use Exporter;


    our $VERSION   = 'v2.1.0';
    our @ISA       = ('Exporter');
    our @EXPORT    = qw(
        $INITDIR
        $HA_DIR
        $HA_RCDIR
        $HA_CONFDIR
        $HA_CF
        $HA_VARLIB
        $HA_RSCTMP
        $HA_RSCTMP_OLD
        $HA_FIFO
        $HA_BIN
        $HA_SBIN_DIR
        $HA_DATEFMT
        $HA_DEBUGLOG
        $HA_RESOURCEDIR
        $HA_DOCDIR
        $__SCRIPT_NAME
        $HA_VARRUN
        $HA_VARLOCK
        $ocf_prefix
        $ocf_exec_prefix
    );
    our @EXPORT_OK = ( @EXPORT );
}

our $INITDIR         = ( $ENV{'INITDIR'}       || '/etc/init.d' );
our $HA_DIR          = ( $ENV{'HA_DIR'}        || '/etc/ha.d' );
our $HA_RCDIR        = ( $ENV{'HA_RCDIR'}      || '/etc/ha.d/rc.d' );
our $HA_CONFDIR      = ( $ENV{'HA_CONFDIR'}    || '/etc/ha.d/conf' );
our $HA_CF           = ( $ENV{'HA_CF'}         || '/etc/ha.d/ha.cf' );
our $HA_VARLIB       = ( $ENV{'HA_VARLIB'}     || '/var/lib/heartbeat' );
our $HA_RSCTMP       = ( $ENV{'HA_RSCTMP'}     || '/var/run/resource-agents' );
our $HA_RSCTMP_OLD   = ( $ENV{'HA_RSCTMP_OLD'} || '/var/run/heartbeat/rsctmp' );
our $HA_FIFO         = ( $ENV{'HA_FIFO'}       || '/var/lib/heartbeat/fifo' );
our $HA_BIN          = ( $ENV{'HA_BIN'}        || '/usr/libexec/heartbeat' );
our $HA_SBIN_DIR     = ( $ENV{'HA_SBIN_DIR'}   || '/usr/sbin' );
our $HA_DATEFMT      = ( $ENV{'HA_DATEFMT'}    || '%Y/%m/%d_%T ' );
our $HA_DEBUGLOG     = ( $ENV{'HA_DEBUGLOG'}   || '/dev/null' );
our $HA_RESOURCEDIR  = ( $ENV{'HA_RESOURCEDIR'}|| '/etc/ha.d/resource.d' );
our $HA_DOCDIR       = ( $ENV{'HA_DOCDIR'}     || '/usr/share/doc/heartbeat' );
our $__SCRIPT_NAME   = ( $ENV{'__SCRIPT_NAME'} || fileparse($0) );
our $HA_VARRUN       = ( $ENV{'HA_VARRUN'}     || '/var/run/' );
our $HA_VARLOCK      = ( $ENV{'HA_VARLOCK'}    || '/var/lock/subsys/' );
our $ocf_prefix      = '/usr';
our $ocf_exec_prefix = '/usr';

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016: Jehan-Guillaume de Rorthais and Mael Rimbault.

Licensed under the PostgreSQL License.

