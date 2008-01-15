use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;

BEGIN { use_ok('HTML::Tested::JavaScript', qw(HTJ));
	use_ok("HTML::Tested::JavaScript::Variable");
};

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Variable", "v");

package main;

my $obj = H->new({ v => "Hello" });
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = \"Hello\";\n</script>" });

$obj->v("Hell\"o");
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = \"Hell\\\"o\";\n</script>" });

$obj->v(0);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = 0;\n</script>" });

$obj->v(1);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = 1;\n</script>" });

$obj->v(undef);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = \"\";\n</script>" });

$obj->v("4a4");
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>\nvar v = \"4a4\";\n</script>" });

