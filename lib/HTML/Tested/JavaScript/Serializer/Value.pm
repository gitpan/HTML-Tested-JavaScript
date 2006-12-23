use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer::Value;
use base 'HTML::Tested::Value';

sub encode_value {
	my ($self, $val) = @_;
	$val =~ s/\\/\\\\/g;
	$val =~ s#/#\\/#g;
	$val =~ s/"/\\"/g;
	return $val;
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return $self->name . ": \"$val\"";
}

1;
