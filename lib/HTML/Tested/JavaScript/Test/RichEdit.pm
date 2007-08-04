package HTML::Tested::JavaScript::Test::RichEdit;
use base 'HTML::Tested::Test::Value', 'Exporter';

our @EXPORT_OK = qw(HTRE_Get_Value HTRE_Set_Value);

sub handle_sealed {
	my ($class, $e_root, $name, $e_val, $r_val, $err) = @_;
	return ($e_val, $r_val);
}

sub check_text {
	my ($class, $e_root, $name, $e_stash, $text) = @_;
	return ($class->SUPER::check_text($e_root, $name, $e_stash, $text)
			, $class->SUPER::check_text($e_root, $name . "_script"
				, $e_stash, $text));
}

sub _Get_Elem {
	my ($mech, $name) = @_;
	return $mech->get_html_element_by_id($name, "IFrame")
			->GetContentDocument()
			->GetElementsByTagName("BODY")->Item(0)
			->QueryInterface(Mozilla::DOM::NSHTMLElement->GetIID);
}

sub HTRE_Get_Value { _Get_Elem(@_)->GetInnerHTML; }

sub HTRE_Set_Value {
	my ($mech, $name, $val) = @_;
	_Get_Elem($mech, $name)->SetInnerHTML($val);
}

1;
