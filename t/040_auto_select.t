use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use Data::Dumper;
use HTTP::Daemon;
use Mozilla::Mechanize::GUITester;
use File::Temp qw(tempdir);
use HTML::Tested::Test::Request;
use File::Slurp;

BEGIN { use_ok('HTML::Tested::JavaScript', qw(HTJ));
	use_ok("HTML::Tested::JavaScript::AutoSelect");
};

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::AutoSelect", "sel");

package main;

my $obj = H->new({ sel => [ [ 1, "One" ], [ 2, "Two", 1 ], [ 3, "Three" ] ] });
my $stash = {};
$obj->ht_render($stash);

my $res = $stash->{sel};
isnt($res, undef);

my $exp = <<ENDS;
<select id="sel" name="sel">
<option value="1">One</option>
<option value="2" selected>Two</option>
<option value="3">Three</option>
</select>
ENDS
like($res, qr#$exp#) or diag(Dumper($stash));

my $td = tempdir('/tmp/ht_auto_XXXXXX', CLEANUP => 1);

my $pid = fork();
if (!$pid) {
	my $d = HTTP::Daemon->new;
	write_file("$td/url", $d->url);
	my $freq = HTML::Tested::Test::Request->new;
	while (my $c = $d->accept) {
		while (my $r = $c->get_request) {
			if ($r->uri =~ /td\/(.*html)$/) {
				$c->send_file_response("$td/$1");
				next;
			}
			my $resp = HTTP::Response->new(200);
			$resp->content("<html><body><pre>"
				. $r->as_string
				. "</pre></body></html>");
			$c->send_response($resp);
		}
		$c->close;
		undef($c);
	}
	exit;
}

sleep 1;

write_file("$td/a.html", <<ENDS);
<html>
<body>
$res
</body>
</html>
ENDS

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
my $d_url = read_file("$td/url");

ok($mech->get("$d_url/td/a.html"));
is_deeply($mech->console_messages, []) or diag($mech->content);
isnt(index($mech->content, $res), -1);

my $sel = $mech->get_html_element_by_id("sel", "Select");
isnt($sel, undef);
is($sel->GetSelectedIndex, 1);

# Silence gtk_main_quit warnings
{
	local *STDERR;
	open(STDERR, ">/dev/null");
	$mech->x_change_select($sel, 2);
}
$mech->x_send_keys("");
like($mech->content, qr/GET.*sel=3/);

kill(9, $pid);
waitpid($pid, 0);

$mech->close;
