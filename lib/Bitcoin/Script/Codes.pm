#!/usr/bin/perl
package Bitcoin::Script::Codes;
use Bitcoin::Script::Stack qw(Push Pop Dup Rot Nip Tuck Swap);

use constant {
    OP_0		=> [   0, sub { Push 0 } ], 
    OP_PUSHDATA1	=> [  76, sub {...} ],
    OP_PUSHDATA2	=> [  77, sub {...} ],
    OP_PUSHDATA4	=> [  78, sub {...} ],
    OP_1NEGATE		=> [  79, sub { Push -1 } ],
    (map { 'OP_'.$_	=> [  80+$_, sub { Push $_ } ] } 1 .. 16),

    OP_NOP		=> [  97, sub { ; } ],
    OP_IF		=> [  99, \&Bitcoin::Script::Stack::If ],
    OP_NOTIF		=> [ 100, \&Bitcoin::Script::Stack::NotIf ],
    OP_ELSE 		=> [ 101, \&Bitcoin::Script::Stack::Else ],
    OP_ENDIF 		=> [ 102, \&Bitcoin::Script::Stack::EndIf ],
    OP_VERIFY		=> [ 103, sub { if (not my $test = Pop) { Push $test; die 'OP_VERIFY' } } ],
    OP_RETURN		=> [ 104, sub { die 'OP_RETURN' } ],

    OP_TOALTSTACK   	=> [ 107, \&Bitcoin::Script::Stack::toAlt ],
    OP_FROMALTSTACK 	=> [ 108, \&Bitcoin::Script::Stack::fromAlt ],
    OP_DROP  		=> [ 109, \&Pop  ],
    OP_ROT   		=> [ 123, \&Rot ],
    OP_SWAP  		=> [ 124, \&Swap ],
    OP_TUCK  		=> [ 125, \&Drop ],
    OP_2DROP 		=> [ 109, sub { Pop, Pop }  ],
    OP_2DUP  		=> [ 110, \&Bitcoin::Script::Stack::TwoDup ],
    OP_3DUP  		=> [ 111, \&Bitcoin::Script::Stack::ThreeDup ],
    OP_2OVER 		=> [ 112, \&Bitcoin::Script::Stack::TwoOver ],
    OP_2ROT  		=> [ 113, \&Bitcoin::Script::Stack::TwoRot ],
    OP_2SWAP 		=> [ 114, \&Bitcoin::Script::Stack::ThreeDup ],
    OP_IFDUP 		=> [ 115, \&Bitcoin::Script::Stack::ThreeDup ],
    OP_DEPTH 		=> [ 116, \&Bitcoin::Script::Stack::ThreeDup ],
    OP_DUP   		=> [ 118, \&Dup ],
    OP_NIP   		=> [ 119, \&Nip ],
    OP_OVER  		=> [ 120, \&Bitcoin::Script::Stack::Over ],
    OP_PICK  		=> [ 121, \&Bitcoin::Script::Stack::Pick ],
    OP_ROLL  		=> [ 122, \&Bitcoin::Script::Stack::Roll ],

    OP_EQUAL		=> [ 135, sub { Push +(Pop eq Pop) ? 1 : 0 } ],
    OP_EQUALVERIFY	=> [ 136, sub { if (Pop ne Pop) { Push 0; die 'OP_EQUALVERIFY' } } ],

    OP_RIPEMD160	=> [ 166, sub { Push qx/perl -e 'print pack "b*", '@{[unpack 'b*', Pop]}' | openssl dgst -rmd160 -binary/ } ],
    OP_SHA1     	=> [ 167, sub { use Digest::SHA qw(sha1);   Push sha1 Pop } ],
    OP_SHA256   	=> [ 168, sub { use Digest::SHA qw(sha256); Push sha256 Pop } ],
    OP_HASH160  	=> [ 169, sub { use Bitcoin::Digest; Push Bitcoin::Digest::hash160_bin Pop } ],
    OP_HASH256  	=> [ 170, sub { use Bitcoin::Digest; Push Bitcoin::Digest::hash256_bin Pop } ],

    OP_CODESEPARATOR    => [ 171, sub {...} ],
    OP_CHECKSIG		=> [ 172,
	sub {
	    use bigint;
	    use EC qw(secp256k1);
	    my $stripped_tx = shift;
	    my $pubkey =
	    Pop =~ /\A\x{04}(.{32})(.{32})\Z/ms ?
	    new EC::DSA::PublicKey $EC::G, bless [ map { hex unpack 'H*' } $1, $2 ], 'EC::Point'
	    : die 'could not extract public key';
	    my ($sig, $hashType) = Pop =~ /(.*)(.)\Z/ms;
	    my @sig = map { $_->{r}, $_->{s} } decode $EC::DSA::ASN::Signature $sig;
	    verify $pubkey
	    Bitcoin::hash_int($stripped_tx->serialize->input . pack 'L<', ord $hashType),
	    @sig;
	    Push 1;
	}
    ],

};

our %Inverse_code = ( map { ${$Bitcoin::Script::Codes::{$_}}->[0] => $_ } grep /\AOP_/, %Bitcoin::Script::Codes:: );

1;

__END__

=begin deprecated
use constant {

    # {{{ Constants
    OP_0 => 0, OP_FALSE	=> 0,   # An empty array of bytes is pushed onto the stack. (This is not a no-op: an item is added to the stack.)
    #  1, 2, ..., 75            # The next opcode bytes is data to be pushed onto the stack
#    (map { 'OP_PUSHDATA0_'.$_ => $_ } 1 .. 75),
    OP_PUSHDATA1 => 76,         # The next byte      contains the number of bytes to be pushed onto the stack.
    OP_PUSHDATA2 => 77,         # The next two bytes contain  the number of bytes to be pushed onto the stack.
    OP_PUSHDATA4 => 78,         # The next four byte contain  the number of bytes to be pushed onto the stack.
    OP_1NEGATE => 79,           # The number -1 is pushed onto the stack.
    OP_1 => 81, OP_TRUE	=> 81,  # The number  1 is pushed onto the stack.
    OP_2 => 82,                 # The number in the word name (2-16) is pushed onto the stack.
    OP_3 => 83,
    OP_4 => 84,
    OP_5 => 85,
    OP_6 => 86,
    OP_7 => 87,
    OP_8 => 88,
    OP_9 => 89,
    OP_10 => 90,
    OP_11 => 91,
    OP_12 => 92,
    OP_13 => 93,
    OP_14 => 94,
    OP_15 => 95,
    OP_16 => 96,
    # }}}
    # {{{ Flow control
    OP_NOP	=> 97,		# Does nothing.
    OP_IF	=> 99,  	# If the top stack value is 1, the statements are executed. The top stack value is removed.
    OP_NOTIF	=> 100, 	# If the top stack value is 0, the statements are executed. The top stack value is removed.
    OP_ELSE	=> 103, 	# If the preceding OP_IF or OP_NOTIF was not executed then these statements are.
    OP_ENDIF	=> 104, 	# Ends an if/else block.
    OP_VERIFY	=> 105, 	# Marks transaction as invalid if top stack value is not true.
                                # True is removed, but false is not.
    OP_RETURN	=> 106, 	# Marks transaction as invalid.
    # }}}
    # {{{ Stack
    OP_TOALTSTACK	=> 107,  # ( x1 -- (alt)x1 )        Puts the input onto the top of the alt stack. Removes it from the main stack.
    OP_FROMALTSTACK	=> 108,  # ( (alt)x1 -- x1 )             Puts the input onto the top of the main stack. Removes it from the alt stack.
    OP_IFDUP        	=> 115,  # ( x -- x / x x )        If the input is true or false, duplicate it.
    OP_DEPTH        	=> 116,  # ( -- <Stack size> )   Puts the number of stack items onto the stack.
    OP_DROP         	=> 117,  # ( x -- )         Removes the top stack item.
    OP_DUP          	=> 118,  # ( x -- x x )     Duplicates the top stack item.
    OP_NIP          	=> 119,  # ( x1 x2 --  x2 )             Removes the second-to-top stack item.
    OP_OVER         	=> 120,  # ( x1 x2 --  x1 x2 x1 )      Copies the second-to-top stack item to the top.
    OP_PICK         	=> 121,  # ( xn ... x2 x1 x0 <n> -- xn ... x2 x1 x0 xn )	The item n back in the stack is copied to the top.
    OP_ROLL         	=> 122,  # ( xn ... x2 x1 x0 <n> -- ... x2 x1 x0 xn )      The item n back in the stack is moved to the top.
    OP_ROT          	=> 123,  # ( x1 x2 x3 -- x2 x3 x1 )       The top three items on the stack are rotated to the left.
    OP_SWAP         	=> 124,  # ( x1 x2 -- x2 x1 )          The top two items on the stack are swapped.
    OP_TUCK         	=> 125,  # ( x1 x2 -- x2 x1 x2 )       The item at the top of the stack is copied and inserted before the second-to-top item.
    OP_2DROP        	=> 109,  # ( x1 x2 -- )         Removes the top two stack items.
    OP_2DUP         	=> 110,  # ( x1 x2 -- x1 x2 x1 x2 )    Duplicates the top two stack items.
    OP_3DUP         	=> 111,  # ( x1 x2 x3 -- x1 x2 x3 x1 x2 x3 ) Duplicates the top three stack items.
    OP_2OVER        	=> 112,  # ( x1 x2 x3 x4  -- x1 x2 x3 x4 x1 x2 ) Copies the pair of items two spaces back in the stack to the front.
    OP_2ROT         	=> 113,  # ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 ) The fifth and sixth items back are moved to the top of the stack.
    OP_2SWAP        	=> 114,  # ( x1 x2 x3 x4  -- x3 x4 x1 x2 )    Swaps the top two pairs of items.
    # }}}
    # {{{ Splice
    OP_CAT    	=> 126,  #   x1 x2         out     Concatenates two strings. Currently disabled.
    OP_SUBSTR 	=> 127,  #   in begin size out     Returns a section of a string. Currently disabled.
    OP_LEFT   	=> 128,  #   in size       out     Keeps only characters left of the specified point in a string. Currently disabled.
    OP_RIGHT  	=> 129,  #   in size       out     Keeps only characters right of the specified point in a string. Currently disabled.
    OP_SIZE   	=> 130,  #   in            in size Returns the length of the input string.
    # }}}
    # {{{ Bitwise logic
    OP_INVERT      	=> 131,  #   in    out          Flips all of the bits in the input. Currently disabled.
    OP_AND         	=> 132,  #   x1 x2 out          Boolean and between each bit in the inputs. Currently disabled.
    OP_OR          	=> 133,  #   x1 x2 out          Boolean or between each bit in the inputs. Currently disabled.
    OP_XOR         	=> 134,  #   x1 x2 out          Boolean exclusive or between each bit in the inputs. Currently disabled.
    OP_EQUAL       	=> 135,  #   x1 x2 True / false Returns 1 if the inputs are exactly equal, 0 otherwise.
    OP_EQUALVERIFY 	=> 136,  #   x1 x2 True / false Same as OP_EQUAL, but runs OP_VERIFY afterward.
    # }}}
    # {{{ Arithmetic
    OP_1ADD               	=> 139,   #   in        out    1 is added to the input.
    OP_1SUB               	=> 140,   #   in        out    1 is subtracted from the input.
    OP_2MUL               	=> 141,   #   in        out    The input is multiplied by 2. Currently disabled.
    OP_2DIV               	=> 142,   #   in        out    The input is divided by 2. Currently disabled.
    OP_NEGATE             	=> 143,   #   in        out    The sign of the input is flipped.
    OP_ABS                	=> 144,   #   in        out    The input is made positive.
    OP_NOT                	=> 145,   #   in        out    If the input is 0 or 1, it is flipped. Otherwise the output will be 0.
    OP_0NOTEQUAL          	=> 146,   #   in        out    Returns 1 if the input is 0. 0 otherwise.
    OP_ADD                	=> 147,   #   a b       out    a is added to b.
    OP_SUB                	=> 148,   #   a b       out    b is subtracted from a.
    OP_MUL                	=> 149,   #   a b       out    a is multiplied by b. Currently disabled.
    OP_DIV                	=> 150,   #   a b       out    a is divided by b. Currently disabled.
    OP_MOD                	=> 151,   #   a b       out    Returns the remainder after dividing a by b. Currently disabled.
    OP_LSHIFT             	=> 152,   #   a b       out    Shifts a left b bits, preserving sign. Currently disabled.
    OP_RSHIFT             	=> 153,   #   a b       out    Shifts a right b bits, preserving sign. Currently disabled.
    OP_BOOLAND            	=> 154,   #   a b       out    If both a and b are not 0, the output is 1. Otherwise 0.
    OP_BOOLOR             	=> 155,   #   a b       out    If a or b is not 0, the output is 1. Otherwise 0.
    OP_NUMEQUAL           	=> 156,   #   a b       out    Returns 1 if the numbers are equal, 0 otherwise.
    OP_NUMEQUALVERIFY     	=> 157,   #   a b       out    Same as OP_NUMEQUAL, but runs OP_VERIFY afterward.
    OP_NUMNOTEQUAL        	=> 158,   #   a b       out    Returns 1 if the numbers are not equal, 0 otherwise.
    OP_LESSTHAN           	=> 159,   #   a b       out    Returns 1 if a is less than b, 0 otherwise.
    OP_GREATERTHAN        	=> 160,   #   a b       out    Returns 1 if a is greater than b, 0 otherwise.
    OP_LESSTHANOREQUAL    	=> 161,   #   a b       out    Returns 1 if a is less than or equal to b, 0 otherwise.
    OP_GREATERTHANOREQUAL 	=> 162,   #   a b       out    Returns 1 if a is greater than or equal to b, 0 otherwise.
    OP_MIN                	=> 163,   #   a b       out    Returns the smaller of a and b.
    OP_MAX                	=> 164,   #   a b       out    Returns the larger of a and b.
    OP_WITHIN             	=> 165,   #   x min max out    Returns 1 if x is within the specified range (left-inclusive), 0 otherwise.
    # }}}
    # {{{ Crypto
    OP_RIPEMD160           	=> 166,  #  ( in -- hash )    The input is hashed using RIPEMD-160.
    OP_SHA1                	=> 167,  #  ( in -- hash )    The input is hashed using SHA-1.
    OP_SHA256              	=> 168,  #  ( in -- hash )    The input is hashed using SHA-256.
    OP_HASH160             	=> 169,  #  ( in -- hash )    The input is hashed twice: first with SHA-256, and then with RIPEMD-160.
    OP_HASH256             	=> 170,  #  ( in -- hash )    The input is hashed two times with SHA-256.
    OP_CODESEPARATOR       	=> 171,  #  ( -- )
					 # All of the signature checking words will only match signatures to the data
					 # after the most recently-executed OP_CODESEPARATOR.  The entire transaction's
					 # outputs, inputs, and script (from the most recently-executed
					 # OP_CODESEPARATOR to the end) are hashed.
    OP_CHECKSIG            	=> 172,  #  ( sig pubkey -- True / false )
					 # The signature used by OP_CHECKSIG must be a valid signature for this hash
					 # and public key. If it is, 1 is returned, 0 otherwise.
    OP_CHECKSIGVERIFY      	=> 173,  #   ( sig pubkey  -- True / false ) Same as OP_CHECKSIG, but OP_VERIFY is executed afterward.  
    OP_CHECKMULTISIG       	=> 174,  #   (
				     #      x sig1 sig2 ...  <number of signatures> pub1 pub2 <number of public keys>
				     #      -- True / False  
				     #   )  
				     #   For each signature and public key pair,
				     #   OP_CHECKSIG is executed.  If more public keys than signatures are
				     #   listed, some key/sig pairscan fail. All
				     #   signatures need to match a public key. If
				     #   all signatures are
				     #   valid, 1 is returned, 0 otherwise. Due to
				     #   a bug, one extra unused value is removed
				     #   from the stack. 
    OP_CHECKMULTISIGVERIFY 	=> 175,  #   ( 
				     #      x sig1 sig2 ...  <number of signatures> pub1 pub2 <number of public keys>
				     #      -- True / False  
				     #   )
				     #   Same as OP_CHECKMULTISIG, but OP_VERIFY is
				     #   executed afterward. 
    # }}}
    # {{{ Pseudo-words
    OP_PUBKEYHASH    	=> 253,  #   Represents a public key hashed with OP_HASH160.
    OP_PUBKEY        	=> 254,  #   Represents a public key compatible with OP_CHECKSIG.
    OP_INVALIDOPCODE 	=> 255,  #   Matches any opcode that is not yet assigned.
    # }}}
    # {{{ Reserved words
    OP_RESERVED      	=>  80,   # Transaction is invalid
    OP_VER           	=>  98,   # Transaction is invalid
    OP_VERIF         	=> 101,   # Transaction is invalid
    OP_VERNOTIF      	=> 102,   # Transaction is invalid
    OP_RESERVED1     	=> 137,   # Transaction is invalid
    OP_RESERVED2     	=> 138,   # Transaction is invalid
    OP_NOP1 => 176,                   # The word is ignored.
    OP_NOP2 => 177,
    OP_NOP3 => 178,
    OP_NOP4 => 179,
    OP_NOP5 => 180,
    OP_NOP6 => 181,
    OP_NOP7 => 182,
    OP_NOP8 => 183,
    OP_NOP9 => 184,
    OP_NOP10 => 185,
    # }}}

};                              
=end deprecated

=cut
