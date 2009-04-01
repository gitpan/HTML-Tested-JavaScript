use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Gtk2::WebKit::Mechanize;

my $mech = Gtk2::WebKit::Mechanize->new;
my $dir = abs_path(dirname($0));
symlink("$dir/../javascript/color_picker.js", "$dir/color_picker.js");

$mech->get("file://$dir/tiger.xhtml");
is($mech->title, 'XHTML test');
is_deeply($mech->console_messages, []);
