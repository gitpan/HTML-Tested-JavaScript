use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Variable;
use base 'HTML::Tested::Value';

sub encode_value {
	my ($self, $val) = @_;
	$val =~ s/\\/\\\\/g;
	$val =~ s#/#\\/#g; # is needed for </script>
	$val =~ s/"/\\"/g;
	$val =~ s/\n/\\n/g;
	$val =~ s/\r//g;
	$val =~ s/[^[:print:]\n\t]+//g;
	return $val;
}

sub variable_value {
	my ($self, $val) = @_;
	return ($val eq "" || $val =~ /\D/) ? "\"$val\"" : $val;
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return sprintf("<script>\nvar \%s = \%s;\n</script>", $name
				, $self->variable_value($val));
}

1;
