use strict;
use warnings FATAL => 'all';

use Test::More tests => 105;
use File::Temp qw(tempdir);
use Mozilla::Mechanize::GUITester;
use File::Slurp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

BEGIN { use_ok("HTML::Tested::JavaScript::ColorPicker");
	use_ok('HTML::Tested::JavaScript', qw(HTJ $Location));
};

$Location = "javascript";

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::ColorPicker", "cp");
__PACKAGE__->ht_add_widget(::HTJ . "::ColorPicker", "nothing");

package main;

my $obj = H->new;
my $stash = {};
$obj->ht_render($stash);
isnt($stash->{cp_color}, undef);
isnt($stash->{cp_hue}, undef);

#use File::Path;
#rmtree("/tmp/ht_color");
#mkdir("/tmp/ht_color");
#my $td = "/tmp/ht_color";
my $td = tempdir('/tmp/ht_color_p_XXXXXX', CLEANUP => 1);
write_file("$td/a.html", <<ENDS);
<html>
<head><title>Color Picker</title>
<script src="javascript/color_picker.js"></script>
<style>
$stash->{cp_color_sample_style}
$stash->{cp_color_style}
$stash->{cp_hue_style}
$stash->{nothing_color_style}
#nothing_color {
	height: 22px;
}
</style>
<script>
htcp_init("nothing", function(name, r, g, b) {
	alert("nothing " + name + " " + r + " " + g + " " + b); 
});
htcp_init("cp", function(name, r, g, b) {
	alert("cp " + name + " " + r + " " + g + " " + b); 
});
</script>
</head>
<body>
<form method="post" action="/just_in_case">
$stash->{nothing_color}
$stash->{nothing_hue}
$stash->{cp_color}
$stash->{cp_hue}
$stash->{cp_rgb_r}
$stash->{cp_rgb_g}
$stash->{cp_rgb_b}
$stash->{cp_rgb_hex}
$stash->{cp_color_sample}
</form>
</body>
</html>
ENDS

symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
ok($mech->get("file://$td/a.html"));
is($mech->title, "Color Picker");
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style_by_id("nothing_color", "height"), "22px");
is($mech->get_element_style_by_id("cp_current_color", "height"), "60px");

unlike($mech->pull_alerts, qr/nothing nothing 255 255 255/);
$mech->run_js('htcp_set_indicators_from_rgb("nothing", 12, 13, 14);');
like($mech->pull_alerts, qr/nothing nothing 12 13 14/);

my $res = $mech->run_js('return htcp_int_to_rgb(122922).toString()');
is($res, '1,224,42') or exit 1;

$res = $mech->run_js('return htcp_rgb_to_hsv(0, 0, 0).toString()');
is_deeply($mech->console_messages, []) or exit 1;
is($res, '0,0,0') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(87, 149, 50).toString()')
	, '98,66,58') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(52, 100, 56).toString()')
	, '125,48,39') or exit 1;
is($mech->run_js('return htcp_rgb_to_hsv(255, 255, 255).toString()')
	, '360,0,100') or exit 1;
is_deeply($mech->console_messages, []) or exit 1;

my $cp_div = $mech->get_html_element_by_id("cp_color");
isnt($cp_div, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($cp_div, "background-image"), qr/pickerbg\.png/);

my $point = $mech->get_html_element_by_id("cp_color_pointer");
isnt($point, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($point, "background-image")
	, qr/color_pointerbg\.gif/);
is_deeply($mech->console_messages, []) or exit 1;

my $cur_color = $mech->get_html_element_by_id("cp_current_color");
isnt($cur_color, undef) or exit 1;

my $prev_color = $mech->get_html_element_by_id("cp_prev_color");
isnt($prev_color, undef) or exit 1;

my $rr = $mech->get_html_element_by_id("cp_rgb_r", "Input");
my $rg = $mech->get_html_element_by_id("cp_rgb_g", "Input");
my $rb = $mech->get_html_element_by_id("cp_rgb_b", "Input");
isnt($rr, undef);
isnt($rg, undef);
isnt($rb, undef);
is($rr->GetValue, 255);
is($rg->GetValue, 255);
is($rb->GetValue, 255);

is($mech->get_element_style($cur_color, "background-color")
	, "rgb(255, 255, 255)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

my $mg1 = $mech->gesture($point);
$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, 22, 22);

my $mg2 = $mech->gesture($point);
is($mg2->element_left - $mg1->element_left, 20);
is($mg2->element_top - $mg1->element_top, 20);
is_deeply($mech->console_messages, []) or exit 1;

is($rr->GetValue, 227);
is($rg->GetValue, 202);
is($rb->GetValue, 202);
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 202)");

$res = $mech->run_js('return htcp_current_color("cp").toString()');
is_deeply($mech->console_messages, []) or exit 1;
is($res, '227,202,202');

$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, 202, 202);

my $mg3 = $mech->gesture($point);
is($mg3->element_left - $mg2->element_left, 161);
is($mg3->element_top - $mg2->element_top, 161);

$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_up($point, -202, -202);

my $mg4 = $mech->gesture($point);
is($mg4->element_left, $mg1->element_left);
is($mg4->element_top, $mg1->element_top);

my $hue = $mech->get_html_element_by_id("cp_hue");
isnt($hue, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($hue, "background-image"), qr/huebg\.png/);

my $hue_ptr = $mech->get_html_element_by_id("cp_hue_pointer");
isnt($hue_ptr, undef) or diag(read_file("$td/a.html"));
like($mech->get_element_style($hue_ptr, "background-image")
	, qr/hue_pointerbg\.gif/);
is($mech->get_element_style($hue_ptr, "width")
	, $mech->get_element_style($hue, "width"));

is($mech->get_element_style($cur_color, "background-color")
	, "rgb(255, 255, 255)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->pull_alerts;
$mech->x_mouse_down($point, 2, 2);
$mech->x_mouse_move($point, 22, 22);
unlike($mech->pull_alerts, qr/cp cp/);

is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->x_mouse_up($point, 2, 2);
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 202)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 202)");
like($mech->pull_alerts, qr/cp cp 227 202 202/);

my $hg1 = $mech->gesture($hue_ptr);
$mech->x_mouse_down($hue_ptr, 2, 2);
$mech->x_mouse_up($hue_ptr, 22, 22);

my $hg2 = $mech->gesture($hue_ptr);
is($hg2->element_left - $hg1->element_left, 0);
is($hg2->element_top - $hg1->element_top, 20);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 162)');
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 218)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 218)");

my $hex = $mech->get_html_element_by_id("cp_rgb_hex", "Input");
isnt($hex, undef) or exit 1;
is($hex->GetValue, 'e3cada');

$mech->run_js('htcp_set_indicators_from_rgb("cp", 255, 255, 255);');
is_deeply($mech->console_messages, []) or exit 1;
is($mech->get_element_style($hue_ptr, "top"), '0px');
is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 0)');
is($mech->get_element_style($point, "left"), '0px');
is($mech->get_element_style($point, "top"), '0px');
is($hex->GetValue, 'ffffff');
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(255, 255, 255)");

$mech->run_js('htcp_set_indicators_from_rgb("cp", 7, 202, 218);');
is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(7, 202, 218)");

$mech->run_js('htcp_set_indicators_from_rgb("cp", 227, 202, 218);');
is($mech->get_element_style($hue_ptr, "top"), '20px');
is($mech->get_element_style($point, "top"), '20px');
is($mech->get_element_style($point, "left"), '20px');

is($mech->get_element_style($cp_div, "background-color"), 'rgb(255, 0, 162)');
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(227, 202, 218)");
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(227, 202, 218)");
is($hex->GetValue, 'e3cada');
is($rr->GetValue, 227);
is($rg->GetValue, 202);
is($rb->GetValue, 218);

$mech->x_click($rr, 3, 3);
$rr->SetValue(7);
$mech->x_send_keys("\n");

is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($hex->GetValue, '07cada');
is_deeply($mech->console_messages, []) or exit 1;

$mech->x_change_text($rg, 100);
is($rr->GetValue, 7);
is($rg->GetValue, 100);
is($rb->GetValue, 218);
is($hex->GetValue, '0764da');
is($mech->get_element_style($cur_color, "background-color")
	, "rgb(7, 100, 218)");

$mech->x_change_text($hex, '07cada');
is_deeply($mech->console_messages, []) or exit 1;
is($rr->GetValue, 7);
is($rg->GetValue, 202);
is($rb->GetValue, 218);
is($hex->GetValue, '07cada');
is($mech->get_element_style($prev_color, "background-color")
	, "rgb(7, 202, 218)");

