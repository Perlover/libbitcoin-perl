#!/usr/bin/perl
use Bitcoin::Constants;
use Bitcoin::DataStream;

package Bitcoin::Database::Berkeley; # aka CDB
use BerkeleyDB;
@ISA = qw(BerkeleyDB::Btree);
use strict;
use warnings;

sub _no_class    { my $_ = shift; die "class method not implemented"    unless ref; return $_ }
sub _no_instance { my $_ = shift; die "instance method not implemented" if ref;     return $_ }

sub new {
    my $class = shift->_no_instance;
    if (scalar(@_) ~~ [1, 2]) {
	my $filename = shift;
	my $subname  = shift // 'main';
	return SUPER::new $class
	-Filename => Bitcoin::Constants::DATA_DIR . "/$filename",
	-Subname  => $subname,
	-Flags    => DB_THREAD| DB_RDONLY,
	    or die "could not open $filename: $!";
    }
    else {...}
}

sub Read {
    my $this = shift->_no_class;
    my $prefix = shift;
    my $kdata = shift;
    my ($k, $v) = (chr(length $prefix) . $prefix . $kdata, '');
    $this->db_cursor->c_get($k, $v, BerkeleyDB::DB_SET);
    return new Bitcoin::DataStream $v;
}

package Bitcoin::Disk::Index;
# virtual base class for Bitcoin::Disk::Block::Index (aka CDiskBlockIndex) and
# Bitcoin::Disk::Tx::Index (aka CDiskTxIndex)

sub prefix();
sub filename();
sub indexed_object();

sub new {
    my $class = shift;
    my $arg = shift;
    my $db = new Bitcoin::Database::Berkeley $class->filename;
    die "could not open database ". $class->filename . ": $!" unless defined $db;
    my $cursor = $db->db_cursor;
    my ($prefix,) = map chr(length). $_, $class->prefix;
    my ($k, $v) = ($prefix, '');
    my $index = bless {}, $class;
    if ($arg =~ s/^(?:0x)?([a-f\d]{64})$/$1/) {
	# exact search
	$k .= reverse pack 'H*', $arg;
	$cursor->c_get($k, $v, BerkeleyDB::DB_SET);
	die 'no such entry' if $cursor->status;
	die "entry was removed" unless defined $v;
	use Bitcoin::DataStream;
	$index->{$arg} = $class->indexed_object->new(new Bitcoin::DataStream $v);
    }
    elsif (ref $arg ~~ [qw(Regexp HASH)]) {
	# regex or hash search
	use Bitcoin::DataStream qw(:types);
	SEARCH: {
	    $cursor->c_get($k, $v, BerkeleyDB::DB_SET_RANGE);
	    do {
		my ($kds, $vds) = map { new Bitcoin::DataStream $_ } $k, $v;
		last SEARCH if $kds->Read(STRING) ne $class->prefix;
		my $hash = unpack 'H*', reverse $kds->Read(BYTE . 32);
		if (ref $arg eq 'Regexp') {
		    $index->{$hash} = $class->indexed_object->new($vds) if $hash =~ $arg;
		}
		else {
		    my $indexed_object = $class->indexed_object->new($vds);
		    for ( grep { exists $indexed_object->{$_} } keys %$arg ) {
			if ($arg->{$_} ne $indexed_object->{$_}) { undef $indexed_object; last }
		    }
		    $index->{$hash} = $indexed_object if defined $indexed_object;
		}
	    } until $cursor->c_get($k, $v, BerkeleyDB::DB_NEXT);
	}
    }
    else {...}
    return $index;
}

package Bitcoin::Block::Index;
sub new {
    my $class = shift;
    die 'instance method call not implemented for this class' if ref $class;
    my $arg = shift;
    if    (ref $arg eq 'Bitcoin::Block')      {...}
    elsif (ref $arg eq 'Bitcoin::DataStream') {
	use Bitcoin::DataStream qw(:types);
	return bless {
	    version   => $arg->Read(INT32),
	    hashNext  => $arg->Read(BYTE . 32),
	    nFile     => $arg->Read(UINT32),
	    nBlockPos => $arg->Read(UINT32),
	    nHeight   => $arg->Read(INT32),
	}, $class;
    }
    else {...}
}

package Bitcoin::Disk::Block::Index;
our @ISA = qw(Bitcoin::Disk::Index);
use Bitcoin::Block;
sub prefix() { 'blockindex' }
sub filename() { 'blkindex.dat' }
sub indexed_object() { 'Bitcoin::Block::Index' }

package Bitcoin::Block;
sub load {
    my $class = shift;
    my $arg = shift;
    if ($arg =~ s/^(?:0x)?([a-f\d]{64})$/$1/) { 
	my $index = new Bitcoin::Disk::Block::Index $arg;
	return $class->new(
	    Bitcoin::DataStream->new->map_file(
		sprintf('%s/blk%04d.dat', Bitcoin::Constants::DATA_DIR, $index->{$arg}{nFile}),
		$index->{$arg}{nBlockPos}
	    )
	);
    }
    else {...}
}
1;


__END__

=head1 TITLE

Bitcoin::Database::Berkeley

=head1 SYNOPSIS

    use Bitcoin::Database::Berkeley;

    my $index = new Bitcoin::Database::Berkeley 'blkindex';

=head1 DESCRIPTION

This modules provides database environnement for opening bitcoin database
created by the vanilla client.

This module is mostly for internal use, as it merely provides tools for
configuring the BerkeleyDB, but it DOES NOT parse the bitcoin-related
serialisation format.  Use Bitcoin::Block or Bitcoin::Transaction to do this.

=head1 AUTHOR

L Grondin <grondilu@yahoo.fr>

=head1 COPYRIGHT AND LICENSE

Copyright 2011, Lucien Grondin.  All rights reserved.  

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself (L<perlgpl>, L<perlartistic>).

=cut
