use strict;
use warnings FATAL => 'all';

use Test::More tests => 115;
use HTML::Tested::JavaScript qw(HTJ);
use HTML::Tested::Test;
use File::Slurp;
use Mozilla::Mechanize::GUITester;
use URI::file;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);

BEGIN { use_ok('HTML::Tested::JavaScript::RichEdit');
	use_ok('HTML::Tested::JavaScript::Test');
}

use constant HTJRE => HTJ."::RichEdit";

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJRE, "v");

package main;

my @v_fn = (v_fontname => <<'ENDS');
<select id="v_fontname" name="v_fontname">
<option value="">Font</option>
<option value="Arial">Arial</option>
<option value="Courier">Courier</option>
<option value="Times New Roman">Times New Roman</option>
<option value="Courier New">Courier New</option>
<option value="Georgia">Georgia</option>
<option value="Trebuchet">Trebuchet</option>
<option value="Verdana">Verdana</option>
<option value="Serif">Serif</option>
</select>
ENDS

my @v_fs = (v_fontsize => <<'ENDS');
<select id="v_fontsize" name="v_fontsize">
<option value="">Size</option>
<option value="1">1</option>
<option value="2">2</option>
<option value="3">3</option>
<option value="4">4</option>
<option value="5">5</option>
<option value="6">6</option>
<option value="7">7</option>
</select>
ENDS

my $obj = T->new;
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { v => '<iframe id="v"></iframe>', v_script => <<'ENDS'
<script src="/html-tested-javascript/rich_edit.js"></script>
<script>
htre_register_on_load("v");
</script>
ENDS
	, @v_fn, @v_fs });

$HTML::Tested::JavaScript::Location = "javascript";
$obj->ht_render($stash);
is_deeply($stash, { v => '<iframe id="v"></iframe>', v_script => <<'ENDS'
<script src="javascript/rich_edit.js"></script>
<script>
htre_register_on_load("v");
</script>
ENDS
	, @v_fn, @v_fs });

my $str = sprintf('<html> <body> %s </body> </html>', $stash->{v});
my @err = HTML::Tested::Test->check_text('T', $str, { v => '' });
isnt($err[0], undef);

$str = sprintf(<<'ENDS'
<html> <head>%s
<style>
#v {
	width: 300px;
	height: 300px;
}
</style>
</head><body> %s </body> </html>
ENDS
		, $stash->{v_script}, $stash->{v});
is_deeply([ HTML::Tested::Test->check_text('T', $str, { v => '' }) ], []);

my $td = tempdir('/tmp/060_re_XXXXXX', CLEANUP => 1);
my $tf = "$td/re.html";
write_file($tf, $str);
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");
ok(-f "$td/javascript/serializer.js");
ok(-f "$td/javascript/rich_edit.js");

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
my $url = URI::file->new_abs($tf)->as_string;
ok($mech->get($url));
is_deeply($mech->console_messages, []) or diag($mech->content);

my $if = $mech->get_html_element_by_id("v", "IFrame")->GetContentDocument()
		->GetElementsByTagName("BODY")->Item(0);
isnt($if, undef) or exit 1;
my $if_ns = $if->QueryInterface(Mozilla::DOM::NSHTMLElement->GetIID);
is($if_ns->GetInnerHTML, "<br>");

$mech->x_click($if, 10, 10);
$mech->x_send_keys('hoho hoho');
is($if_ns->GetInnerHTML, "hoho hoho<br>");
is($mech->run_js('return htre_get_value("v");'), "hoho hoho<BR/>");
is($mech->run_js('return htre_document("v");'), '[object HTMLDocument]');
is_deeply($mech->console_messages, []) or exit 1;

use_ok('HTML::Tested::JavaScript::Test::RichEdit', qw(HTRE_Get_Value
			HTRE_Set_Value HTRE_Get_Body));
is(HTRE_Get_Value($mech, "v"), "hoho hoho<br>");
is(HTRE_Get_Body($mech, "v")->GetInnerHTML, HTRE_Get_Value($mech, "v"));

$mech->run_js('htre_set_value("v", "momo<p>mama");');
is($mech->run_js('return htre_get_value("v");'), "momo<P>mama</P>");
is($if_ns->GetInnerHTML, "momo<p>mama</p>");
$mech->pull_alerts;
is($mech->run_js('return htre_escape(htre_get_value("v"));'),
	'momo<P>mama</P>');

T->ht_set_widget_option("v", "no_onload", 1);
$obj->ht_render($stash);
is_deeply($stash, { v => '<iframe id="v"></iframe>', v_script => <<'ENDS'
<script src="javascript/rich_edit.js"></script>
ENDS
	, @v_fn, @v_fs });


$str = sprintf(<<'ENDS'
<html> <head>%s
<style>
#v {
	width: 300px;
	height: 300px;
}
</style>
<script>
function init() {
	document.getElementById("moo").style.display = "";
	htre_init("v");
	htre_add_onchange_listener("v", function() {
		alert("Hello " + htre_get_value("v"));
	});
}
</script>
</head><body> <div id="moo" style="display: none;">%s</div> </body> </html>
ENDS
		, $stash->{v_script}, $stash->{v});
my $tf_none = "$td/re_none.html";
write_file($tf_none, $str);

my $url_none = URI::file->new_abs($tf_none)->as_string;
ok($mech->get($url_none));
is_deeply($mech->console_messages, []);

$mech->run_js("init()");
is(HTRE_Get_Value($mech, "v"), "<br>");

unlike($mech->pull_alerts, qr/Hello/);
$if = $mech->get_html_element_by_id("v");
$mech->x_click($if, 10, 10);
$mech->x_send_keys('hoho hoho');
$mech->x_click($if, -5, -5);
is(HTRE_Get_Value($mech, "v"), "hoho hoho<br>");
like($mech->pull_alerts, qr/Hello hoho hoho/);
is_deeply($mech->console_messages, []);

HTRE_Set_Value($mech, "v", "baba");
is(HTRE_Get_Value($mech, "v"), "baba");

T->ht_set_widget_option("v", "no_onload", undef);
$obj->ht_render($stash);
$str = sprintf(<<'ENDS'
<html> <head>%s
<title>Commands</title>
<style>
#v {
	width: 300px;
	height: 300px;
}
</style>
</head><body>
<div id="v_bold">Bold</div>
<div id="v_italic">Italic</div>
<div id="v_underline">Underline</div>
%s
</body> </html>
ENDS
		, $stash->{v_script}, $stash->{v});
my $tf_cmds = "$td/cmds.html";
write_file($tf_cmds, $str);

my $url_cmds = URI::file->new_abs($tf_cmds)->as_string;
ok($mech->get($url_cmds));
is($mech->title, "Commands");
is_deeply($mech->console_messages, []);

my $bo = $mech->get_html_element_by_id("v_bold");
isnt($bo, undef) or exit 1;
$mech->x_click($bo, 2, 2);

my $vif = $mech->get_html_element_by_id("v");
isnt($vif, undef) or exit 1;
$mech->x_send_keys('hoho hoho');
is(HTRE_Get_Value($mech, "v"), '<span style="font-weight: bold;">'
	. 'hoho hoho<br></span>');
is_deeply($mech->console_messages, []);
is($mech->run_js('return htre_get_selection_state("v").bold;'), 'bold');
is_deeply($mech->console_messages, []) or exit 1;

HTRE_Set_Value($mech, "v", '<span style="font-weight: normal;">'
	. 'hoho hoho</span>');
$mech->x_click($if, 10, 10);
$mech->x_send_keys('{RIG}');
is($mech->run_js('return htre_get_selection_state("v").bold;'), 'normal');

HTRE_Set_Value($mech, "v", '<span style="font-weight: bold;">'
	. '<script>var _a;</script>hoho hoho<br></span>');
$mech->pull_alerts;
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<SPAN style="font-weight: bold;">hoho hoho<BR/></SPAN>');
is_deeply($mech->console_messages, []) or exit 1;

HTRE_Set_Value($mech, "v", '<span style="font-weight: bold;" onclick="boom();">'
	. '<script>var _a;</script>hoho hoho<br></span>');
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<SPAN style="font-weight: bold;">hoho hoho<BR/></SPAN>');
is_deeply($mech->console_messages, []);

my $ital = $mech->get_html_element_by_id("v_italic");
isnt($ital, undef) or exit 1;
$mech->x_click($bo, 2, 2);
$mech->x_click($ital, 2, 2);

HTRE_Set_Value($mech, "v", "");
$mech->x_send_keys('haha haha');
is(HTRE_Get_Value($mech, "v"), '<span style="font-style: italic;">'
	. '<span style="font-weight: bold;">haha haha<br></span></span>');
is_deeply($mech->console_messages, []);
is($mech->run_js('return htre_get_selection_state("v").italic;'), 'italic');

HTRE_Set_Value($mech, "v", "");
my $under = $mech->get_html_element_by_id("v_underline");
isnt($under, undef) or exit 1;
$mech->x_click($under, 2, 2);

$mech->x_send_keys('haha haha');
is(HTRE_Get_Value($mech, "v")
	, '<span style="text-decoration: underline;">haha haha<br></span>');
is($mech->run_js('return htre_get_selection_state("v").underline;')
	, 'underline');
is_deeply($mech->console_messages, []);

$mech->x_click($bo, 2, 2);
$mech->x_send_keys('bbb');
is($mech->run_js('return htre_get_selection_state("v").bold;'), 'bold');
is($mech->run_js('return htre_get_selection_state("v").underline;')
	, 'underline') or exit 1;

my $ix = $mech->run_js('return htre_get_inner_xml(document.body)');
is_deeply($mech->console_messages, []);
is($ix, <<ENDS);

<DIV id="v_bold">Bold</DIV>
<DIV id="v_italic">Italic</DIV>
<DIV id="v_underline">Underline</DIV>
<IFRAME id="v"/>
ENDS

$str = sprintf(<<'ENDS'
<html> <head>%s
<title>Fontname</title>
<style>
#v {
	width: 300px;
	height: 300px;
}
</style>
<script>
function do_hide() {
	document.getElementById("h").style.display = "none";
}
</script>
</head><body>
<div id="v_justifycenter">JCenter</div>
<div id="v_justifyleft">JLeft</div>
<div id="v_justifyright">JRight</div>
<div id="v_insertorderedlist">OList</div>
<div id="v_insertunorderedlist">UList</div>
<div id="v_outdent">Outdent</div>
<div id="v_indent">Indent</div>
<div id="v_undo">Undo</div>
<div id="v_redo">Redo</div>
<div id="foci" onclick="javascript:htre_focus('v')">Foci</div>
<div id="hide" onclick="javascript:do_hide()">hide</div>
%s
%s
<div id="h">
%s
</div>
</body> </html>
ENDS
		, $stash->{v_script}, $stash->{v_fontsize}
		, $stash->{v_fontname}, $stash->{v});
my $tf_fn = "$td/fn.html";
write_file($tf_fn, $str);

my $url_fn = URI::file->new_abs($tf_fn)->as_string;
ok($mech->get($url_fn));
is($mech->title, "Fontname");
is_deeply($mech->console_messages, []);

my $fn_sel = $mech->get_html_element_by_id("v_fontname", "Select");
isnt($fn_sel, undef) or exit 1;
$mech->pull_alerts;

my $fs_sel = $mech->get_html_element_by_id("v_fontsize", "Select");
isnt($fs_sel, undef) or exit 1;

$mech->x_change_select($fn_sel, 2);
$mech->x_change_select($fs_sel, 2);
$vif = $mech->get_html_element_by_id("v");
isnt($vif, undef) or exit 1;

$mech->x_send_keys('fn fn');
my $gv = '<font size="2"><span style="font-family: '
		. 'Courier;">fn fn<br></span></font>';
is(HTRE_Get_Value($mech, "v"), $gv);
is($mech->run_js('return htre_get_selection_state("v").fontname;'), 'Courier');
is($mech->run_js('return htre_get_selection_state("v").fontsize;'), 2);
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<FONT size="2"><SPAN style="font-family: Courier;">fn fn<BR/>'
	. '</SPAN></FONT>');
$mech->run_js('htre_exec_command("v", "forecolor", "#012345");');
$mech->x_send_keys('bo bo');
is(HTRE_Get_Value($mech, "v"), '<font size="2"><span style="font-family: '
		. 'Courier;">fn fn<span style="color: rgb(1, 35, 69);">'
		. 'bo bo</span><br></span></font>');
is($mech->run_js('return htre_get_selection_state("v").forecolor;')
	, 'rgb(1, 35, 69)');

$mech->x_change_select($fs_sel, 4);
$mech->x_send_keys('fo fo');
is(HTRE_Get_Value($mech, "v"), '<font size="2"><span style="font-family: '
		. 'Courier;">fn fn<span style="color: rgb(1, 35, 69);">'
		. 'bo bo<font size="4">fo fo</font></span><br></span></font>');
is($mech->run_js('return htre_get_selection_state("v").fontsize;'), 4);
like($mech->run_js('return htre_get_selection_state("v").selection.anchorNode;')
	, qr/object/);
is_deeply($mech->console_messages, []) or exit 1;

HTRE_Set_Value($mech, "v", "");
$mech->run_js('htre_exec_command("v", "hilitecolor", "#ffccdd");');
$mech->x_send_keys('c');
$mech->x_change_select($fs_sel, 6);
$mech->x_send_keys('fh fh');
is(HTRE_Get_Value($mech, "v"), '<span style="background-color: '
	. 'rgb(255, 204, 221);">c<font size="6">fh fh<br></font></span>');
is($mech->run_js('return htre_get_selection_state("v").hilitecolor;')
	, 'rgb(255, 204, 221)');

HTRE_Set_Value($mech, "v", "");
my $jc = $mech->get_html_element_by_id("v_justifycenter");
$mech->x_click($jc, 2, 2);
$mech->x_send_keys("goo goo");
is(HTRE_Get_Value($mech, "v"), '<div style="text-align: center;">goo goo<br>'
		. '</div>');
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<DIV style="text-align: center;">goo goo<BR/></DIV>');
is($mech->run_js('return htre_get_selection_state("v").justifycenter;')
	, 'true');

$mech->run_js('htre_exec_command("v", "hilitecolor", "#ffccdd");');
$mech->x_send_keys('bc bc');
is(HTRE_Get_Value($mech, "v"), '<div style="text-align: center;">goo goo'
	. '<span style="background-color: rgb(255, 204, 221);">'
	. 'bc bc</span><br></div>');
is($mech->run_js('return htre_get_selection_state("v").hilitecolor;')
	, 'rgb(255, 204, 221)');

for (qw(left right)) {
	HTRE_Set_Value($mech, "v", "");
	$mech->x_click($mech->get_html_element_by_id("v_justify$_"), 2, 2);
	$mech->x_send_keys($_);
	is(HTRE_Get_Value($mech, "v"), "<div style=\"text-align: $_;\">$_"
			. "<br></div>");
	is($mech->run_js('return htre_get_selection_state("v").justify'
		. "$_;"), 'true');
}
is($mech->run_js('return htre_get_selection_state("v").justifycenter;')
	, 'undefined');

HTRE_Set_Value($mech, "v", "");
$mech->x_click($mech->get_html_element_by_id("v_insertorderedlist"), 2, 2);
$mech->x_send_keys("aaa\nbbb");
is(HTRE_Get_Value($mech, "v"), '<ol><li>aaa</li><li>bbb<br></li></ol>');
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<OL><LI>aaa</LI><LI>bbb<BR/></LI></OL>');
is($mech->run_js('return htre_get_selection_state("v").insertorderedlist;')
	, 'true');

HTRE_Set_Value($mech, "v", "");
$mech->x_click($mech->get_html_element_by_id("v_insertunorderedlist"), 2, 2);
$mech->x_send_keys("aaa\nbbb");
is(HTRE_Get_Value($mech, "v"), '<ul><li>aaa</li><li>bbb<br></li></ul>');
is($mech->run_js('return htre_escape(htre_get_value("v"));')
	, '<UL><LI>aaa</LI><LI>bbb<BR/></LI></UL>');
is($mech->run_js('return htre_get_selection_state("v").insertunorderedlist;')
	, 'true');
is($mech->run_js('return htre_get_selection_state("v").insertorderedlist;')
	, 'undefined');

HTRE_Set_Value($mech, "v", "");
$mech->x_click($mech->get_html_element_by_id("v_indent"), 2, 2);
$mech->x_send_keys("aaa");
is(HTRE_Get_Value($mech, "v"), '<div style="margin-left: 40px;">aaa<br></div>');

$mech->x_click($mech->get_html_element_by_id("v_indent"), 2, 2);
$mech->x_click($mech->get_html_element_by_id("v_indent"), 2, 2);
$mech->x_click($mech->get_html_element_by_id("v_outdent"), 2, 2);
$mech->x_send_keys("aaa");
is(HTRE_Get_Value($mech, "v")
	, '<div style="margin-left: 80px;">aaaaaa<br></div>');

is($mech->run_js('return htre_get_selection("v").getRangeAt(0);'), '');
is_deeply($mech->console_messages, []);
is($mech->run_js('return htre_escape("<moo />");'), '');

# check that inner_xml removes enclosing tags
is($mech->run_js('return htre_get_inner_xml('
	. 'document.getElementById("v_outdent"));'), 'Outdent');

$mech->x_click($mech->get_html_element_by_id("v_undo"), 2, 2);
is(HTRE_Get_Value($mech, "v")
	, '<div style="margin-left: 80px;">aaa<br></div>');

$mech->x_click($mech->get_html_element_by_id("v_redo"), 2, 2);
is(HTRE_Get_Value($mech, "v")
	, '<div style="margin-left: 80px;">aaaaaa<br></div>');

$mech->x_send_keys("^(a)");
$mech->run_js('htre_exec_command("v", "CreateLink", "a.com");');
is(HTRE_Get_Value($mech, "v"), '<div style="margin-left: 80px;">'
		. '<a href="a.com">aaaaaa<br></a></div>');
is($mech->run_js('return htre_escape(htre_get_value("v"));'),
		'<DIV style="margin-left: 80px;"><A href="a.com">aaaaaa<BR/>'
		.  '</A></DIV>');
is($mech->run_js('return htre_get_selection("v").getRangeAt(0);'), 'aaaaaa');

$mech->x_click($mech->get_html_element_by_id("foci"), 2, 2);
$mech->x_send_keys('sa');
is_deeply($mech->console_messages, []);
is(HTRE_Get_Value($mech, "v"), 'sa');
$mech->x_change_select($fn_sel, 8);
$mech->x_send_keys('fa');
is($mech->run_js('return htre_get_selection_state("v").fontname;'), 'Serif');
is($mech->run_js('return htre_get_selection_state("v").bold;'), '');
is_deeply($mech->console_messages, []);

$mech->run_js(<<'ENDS');
htre_listen_for_state_changes("v", function(n, sch) {
	alert("sch " + sch.fontname + " " + n);
}, 20);
ENDS
is_deeply($mech->console_messages, []) or exit 1;

$mech->pull_alerts;
$mech->x_send_keys('{RIG}');
like($mech->pull_alerts, qr/sch Serif v/);

$mech->x_click($mech->get_html_element_by_id("foci"), -3, -3);
like($mech->pull_alerts, qr/sch Serif v/);

$mech->x_click($mech->get_html_element_by_id("foci"), 3, 3);
like($mech->pull_alerts, qr/sch Serif v/);

$mech->x_send_keys("^(a)");
$mech->run_js('htre_exec_command("v", "CreateLink", "a.com");');
is(HTRE_Get_Value($mech, "v"), '<a href="a.com">sa<span style="font-family:'
	. ' Serif;">fa</span></a>');

$mech->x_click($mech->get_html_element_by_id("v"), 10, 10);
is($mech->run_js('return htre_get_selection_state("v").link;'), 'a.com');

$mech->x_click($mech->get_html_element_by_id("hide"), 3, 3);
is_deeply($mech->console_messages, []) or exit 1;
