use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;
use Data::Dumper;
use HTML::Tested::Test;
use HTML::Tested::JavaScript::Test;

BEGIN { use_ok('HTML::Tested::JavaScript::Serializer');
	use_ok('HTML::Tested::JavaScript::Serializer::Value');
	use_ok('HTML::Tested::JavaScript::Serializer::List');
}

use constant HTJ => "HTML::Tested::JavaScript::Serializer";

is($HTML::Tested::JavaScript::Location, "/html-tested-javascript");
is(HTML::Tested::JavaScript::Script_Include(),
	"<script src=\"/html-tested-javascript/serializer.js\"></script>\n");

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Value", "v");

package main;

my $obj = T->new({ v => 'a' });
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { v => 'v: "a"' });

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::List", "l", 'T');

package main;

$obj = T2->new({ l => [ map { T->new({ v => $_ }) } (1 .. 2) ] });
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l => [ {
	v => 'v: "1"'
}, {
	v => 'v: "2"'
}], l_js => 'l: [ {
	v: "1"
}, {
	v: "2"
} ]'}) or diag(Dumper($stash));

T->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "v2");
$obj = T2->new({ l => [ map { T->new({ v => $_, v2 => $_ }) } (1 .. 2) ] });
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l => [ {
	v => 'v: "1"',
	v2 => 'v2: "1"'
}, {
	v => 'v: "2"',
	v2 => 'v2: "2"'
} ], l_js => 'l: [ {
	v: "1",
	v2: "1"
}, {
	v: "2",
	v2: "2"
} ]'}) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash,
		{ l => [ { v2 => '1', v => '1' }, 
				{ v2 => '2', v => '2' } ] }) ], []);

T->ht_add_widget("HTML::Tested::Value", "v3");
$obj = T2->new({ l => [ map { T->new({ v => $_, v2 => $_, v3 => $_ }) }
					(1 .. 2) ] });
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l => [ {
	v => 'v: "1"',
	v2 => 'v2: "1"',
	v3 => "1"
}, {
	v => 'v: "2"',
	v2 => 'v2: "2"',
	v3 => '2'
} ], l_js => 'l: [ {
	v: "1",
	v2: "1"
}, {
	v: "2",
	v2: "2"
} ]'}) or diag(Dumper($stash));

$obj->l->[0]->v("</scRipt>\n");
$obj->l->[0]->v2("\\f");
$obj->l->[1]->v2("dd\"dd");
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l => [ {
	v => 'v: "<\\/scRipt>\n"',
	v2 => 'v2: "\\\\f"',
	v3 => "1"
}, {
	v => 'v: "2"',
	v2 => 'v2: "dd\\"dd"',
	v3 => '2'
} ], l_js => 'l: [ {
	v: "<\\/scRipt>\n",
	v2: "\\\\f"
}, {
	v: "2",
	v2: "dd\\"dd"
} ]'}) or diag(Dumper($stash));

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Value", "v$_") for (0 .. 3);
__PACKAGE__->ht_add_widget(::HTJ, "ser", map { "v$_" } (0 .. 3));

package main;

$obj = T3->new({ map { ("v$_", $_) } (0 .. 3) });
$stash = {};
$obj->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash
			, { ser => '', map { ("v$_", $_) } (0 .. 3) }) ], []);

eval {
package TXX;
use base 'HTML::Tested';
__PACKAGE__->make_tested_value("x");
__PACKAGE__->ht_add_widget(::HTJ, "ser", 'xxx');
};
like($@, qr/Unable to find.*xxx/);

my @cs = HTML::Tested::Test->check_stash(ref($obj), $stash, { ser => '' });
like($cs[0], qr/Mismatch/);
