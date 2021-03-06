# MyTestHelpers.pm -- my shared test script helpers

# Copyright 2008, 2009 Kevin Ryde

# MyTestHelpers.pm is shared by several distributions.
#
# MyTestHelpers.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyTestHelpers.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyTestHelpers;
use strict;
use warnings;

use base 'Exporter';
use vars qw(@EXPORT_OK %EXPORT_TAGS);
our @EXPORT_OK = qw(findrefs
                    main_iterations
                    warn_suppress_gtk_icon
                    glib_gtk_versions
                    any_signal_connections);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant DEBUG => 0;


#-----------------------------------------------------------------------------

sub findrefs {
  my ($obj) = @_;
  defined $obj or return;
  require Scalar::Util;
  if (ref $obj && Scalar::Util::reftype($obj) eq 'HASH') {
    Test::More::diag ("Keys: ", join(',', keys %$obj), "\n");
  }
  if (eval { require Devel::FindRef }) {
    Test::More::diag (Devel::FindRef::track($obj, 8));
  } else {
    Test::More::diag ("Devel::FindRef not available -- $@\n");
  }
}

#-----------------------------------------------------------------------------
# Gtk/Glib helpers

# Gtk 2.16 can go into a hard loop on events_pending() / main_iteration_do()
# if dbus is not running, or something like that.  In any case limiting the
# iterations is good for test safety.
#
sub main_iterations {
  my $count = 0;
  if (DEBUG) { Test::More::diag ("main_iterations() ..."); }
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);

    if ($count >= 500) {
      Test::More::diag ("main_iterations(): oops, bailed out after $count events/iterations");
      return;
    }
  }
  Test::More::diag ("main_iterations(): ran $count events/iterations");
}

# Eg,
#     my $something = do {
#       local $SIG{'__WARN__'} = \&warn_suppress_gtk_icon;
#       SomeThing->new;
#     };
#
sub warn_suppress_gtk_icon {
  my ($message) = @_;
  unless ($message =~ /Gtk-WARNING.*icon/) {
    warn @_;
  }
}

sub glib_gtk_versions {
  my $gtk2_loaded = Gtk2->can('init');
  my $glib_loaded = Glib->can('get_home_dir');

  if ($gtk2_loaded) {
    Test::More::diag ("Perl-Gtk2    version ",Gtk2->VERSION);
  }
  if ($glib_loaded) { # when loaded
    Test::More::diag ("Perl-Glib    version ",Glib->VERSION);
    Test::More::diag ("Compiled against Glib version ",
                      Glib::MAJOR_VERSION(), ".",
                      Glib::MINOR_VERSION(), ".",
                      Glib::MICRO_VERSION(), ".");
    Test::More::diag ("Running on       Glib version ",
                      Glib::major_version(), ".",
                      Glib::minor_version(), ".",
                      Glib::micro_version(), ".");
  }
  if ($gtk2_loaded) {
    Test::More::diag ("Compiled against Gtk version ",
                      Gtk2::MAJOR_VERSION(), ".",
                      Gtk2::MINOR_VERSION(), ".",
                      Gtk2::MICRO_VERSION(), ".");
    Test::More::diag ("Running on       Gtk version ",
                      Gtk2::major_version(), ".",
                      Gtk2::minor_version(), ".",
                      Gtk2::micro_version(), ".");
  }
}

# return true if there's any signal handlers connected to $obj
sub any_signal_connections {
  my ($obj) = @_;
  my @connected = grep {$obj->signal_handler_is_connected ($_)} (0 .. 500);
  if (@connected) {
    my $connected = join(',',@connected);
    Test::More::diag ("$obj signal handlers connected: $connected");
    return $connected;
  }
  return undef;
}

1;
__END__
