use strict;

use Test;
BEGIN { plan tests => 8 }

use Bitcoin;
use Bitcoin::Base58 qw(encode decode);

ok decode('z'), 57;
ok decode('1z'), 57;
ok decode('211'), 58*58;
ok decode('2z'), 57+58;
ok encode(10), 'B';

my $r = int rand 1000;
ok decode(encode $r), $r, "consistency check failed from random integer";

use bigint;
ok decode(encode 2**20), 2**20, "consistency check failed from an integer";
ok encode(decode 'Grondi1u'), 'Grondi1u', "consistency check failed from base58 string";


ok encode(decode('1QAVk6rZ8Tzj6665X3v1yPGfKwNHFjGV4y')), 'QAVk6rZ8Tzj6665X3v1yPGfKwNHFjGV4y';

ok decode(encode 63818740020046288587078830213417531626340256228101039527607392631150669667302654597324335),
63818740020046288587078830213417531626340256228101039527607392631150669667302654597324335;
