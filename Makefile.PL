use strict;
use warnings;

use inc::Module::Install;

name 'libbitcoin-perl';
abstract 'Bitcoin module';

author 'grondilu';
version_from 'Bitcoin.pm';
auto_set_repository;
license 'perl';
perl_version 5.14;

requires 'BerkeleyDB';
requires 'Convert::ASN1';
requires 'File::Map';

build_requires 'Test::More';
build_requires 'Test::Base';

WriteAll();

package MY;
