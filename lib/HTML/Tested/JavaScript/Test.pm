use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Test::Serializer;
use base 'HTML::Tested::Test::Value';

sub _is_anyone_sealed {
	my ($class, $e_root, $js) = @_;
	return 1 if $e_root->{"__HT_SEALED__$js"};
	my $a = $e_root->{$js};
	return undef unless ref($a);
	for my $r (@$a) {
		for my $k (keys %$r) {
			return 1 if $class->_is_anyone_sealed($r, $k);
		}
	}
	return undef;
}

sub _handle_sealed {
	my ($class, $e_root, $name, $e_val, $r_val, $err) = @_;
	my $ser_widget = $e_root->ht_find_widget($name);
	for my $j (@{ $ser_widget->{_jses} }) {
		next unless $class->_is_anyone_sealed($e_root, $j);
		$e_root->{"__HT_SEALED__$name"} = 1;
		last;
	}
	return shift()->SUPER::_handle_sealed(@_);
}

package HTML::Tested::JavaScript::Test;
use HTML::Tested::Test;
use HTML::Tested::JavaScript::Serializer;

{
	no strict 'refs';
	*{ "HTML::Tested::JavaScript::Serializer::__ht_tester" } = sub {
		return 'HTML::Tested::JavaScript::Test::Serializer'; };
};

1;
