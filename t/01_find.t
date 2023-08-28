use strict;
use warnings;
use Test2::V0 qw( done_testing ok );

use lib 't/lib';
use Namespace::Subroutines ();

my %subroutines;
Namespace::Subroutines::find(
    'ToDo::Controller',
    sub {
        my ( $modules, $name, $ref, $attrs ) = @_;
        $subroutines{$name} = 1;
    }
);

ok( $subroutines{foo}, 'finds subroutine "foo"' );
ok( $subroutines{bar}, 'finds subroutine "bar"' );

done_testing;
