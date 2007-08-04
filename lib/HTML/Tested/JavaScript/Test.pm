use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Test::Serializer;
use base 'HTML::Tested::Test::Value';

sub _is_anyone_sealed {
	my ($class, $e_root, $js) = @_;
	return 1 if $class->SUPER::is_marked_as_sealed($e_root, $js);
	my $a = $e_root->{$js};
	return undef unless ref($a);
	for my $r (@$a) {
		for my $k (keys %$r) {
			return 1 if $class->_is_anyone_sealed($r, $k);
		}
	}
	return undef;
}

sub is_marked_as_sealed {
	my ($class, $e_root, $name) = @_;
	my $ser_widget = $e_root->ht_find_widget($name);
	for my $j (@{ $ser_widget->{_jses} }) {
		next unless $class->_is_anyone_sealed($e_root, $j);
		return 1;
	}
	return undef;
}

package HTML::Tested::JavaScript::Test;
use HTML::Tested::Test qw(Register_Widget_Tester);
use HTML::Tested::JavaScript::Serializer;
use HTML::Tested::JavaScript::RichEdit;
use HTML::Tested::JavaScript::Test::RichEdit;

Register_Widget_Tester("HTML::Tested::JavaScript::Serializer"
		, 'HTML::Tested::JavaScript::Test::Serializer');
Register_Widget_Tester("HTML::Tested::JavaScript::RichEdit"
		, 'HTML::Tested::JavaScript::Test::RichEdit');

1;
