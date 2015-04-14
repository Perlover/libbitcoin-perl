#!/usr/bin/perl
package Bitcoin::Script::Stack;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(Push Pop Dup Rot Nip Tuck Swap);

use strict;
use warnings;

my (@S, @alt_S);	# main and alternate stacks
my @if_else_endif;	# conditional structure stack

sub check_size($)	{ die "stack is too small" if @S < shift }

sub Pop			{ check_size 1; pop @S }
sub Push		{ push @S, @_ }

sub toAlt               { push @alt_S, Pop }
sub fromAlt             { Push pop @alt_S  }

sub Dup                 { check_size 1; push @S, $S[$#S] }
sub Nip                 { check_size 2; splice @S, -2, 1 }
sub Tuck                { check_size 2; splice @S, -2, 0, $S[$#S] }
sub Rot                 { check_size 3; push @S, splice @S, -3, 1 }
sub Swap                { check_size 2; push @S, splice @S, -2, 1 }

sub If;
sub NotIf;
sub Else;
sub Endif;

sub TwoDup;
sub ThreeDup;

1;

__END__
sub TwoDup	{ check_size 2; push @S, @S[$#S-1,$S] }
sub ThreeDup	{ check_size 3; push @S, @S[$#S-2,$S] }
