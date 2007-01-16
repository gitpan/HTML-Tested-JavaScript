use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::AutoSelect;
use base 'HTML::Tested::Value::DropDown';

sub value_to_string {
	my ($self, $name, $val) = @_;
	my $res = $self->SUPER::value_to_string($name, $val);
	return <<ENDS
<form>$res</form>
<script>
document.getElementById("$name").onchange = function() { this.form.submit(); };
</script>
ENDS
}

1;
