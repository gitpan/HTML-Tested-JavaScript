=head1 NAME

HTML::Tested::JavaScript::Serializer - Serialize HTML::Tested to/from JavaScript.

=head1 SYNOPSIS

  package MyClass;
  use base 'HTML::Tested';
  use HTML::Tested::JavaScript::Serializer;
  use HTML::Tested::JavaScript::Serializer::Value;
  
  use constant HTJS => "HTML::Tested::JavaScript::Serializer";

  # add JS Value named "val".
  __PACKAGE__->ht_add_widget(HTJS . "::Value", "val");

  # add serializer "ser" and bind "val" to it.
  __PACKAGE__->ht_add_widget(HTJS, "ser", "val");

  # now MyClass->ht_render produces ser javascript variable

  # in your HTML file serialize back
  ht_serializer_submit(ser, url, callback);

=head1 DESCRIPTION

This module serializes data to/from JavaScript data structures.
It also produces script tags to include necessary JavaScript files.

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
=head1 SEE ALSO

HTML::Tested, HTML::Tested::JavaScript::Serializer::Value,
HTML::Tested::JavaScript::Serializer::List.

Tests for HTML::Tested::JavaScript.

=cut 

use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript::Serializer;
use HTML::Tested;
use HTML::Tested::JavaScript;
use Carp;

sub new {
	my ($class, $parent, $name, @jses) = @_;
	my $self = bless({ name => $name, _jses => \@jses }, $class);
	my @unknowns = grep { !$parent->ht_find_widget($_) } @jses;
	confess "$class: Unable to find js controls: " . join(', ', @unknowns)
			 if @unknowns;
	return $self;
}

sub name { return shift()->{name}; }

sub render {
	my ($self, $caller, $stash, $id) = @_;
	my $n = $self->name;
	my $res = HTML::Tested::JavaScript::Script_Include()
		. "<script>\nvar $n = {\n\t"
		. join(",\n\t", grep { $_ } map {
				my $r = $stash->{$_};
				ref($r) ? $stash->{$_ . "_js"} : $r
			} @{ $self->{_jses} })
		. "\n};\n</script>";
	$stash->{ $n } = $res;
}

sub bless_from_tree { return $_[1]; }
sub options { return {}; }

1;
