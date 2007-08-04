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
	return $val;
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return "<script>\nvar $name = \"$val\";\n</script>";
}

1;
