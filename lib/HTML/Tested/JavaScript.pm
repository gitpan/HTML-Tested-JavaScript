=head1 NAME

HTML::Tested::JavaScript - JavaScript enabled HTML::Tested widgets.

=head1 SYNOPSIS

  use HTML::Tested::JavaScript;
  
  # set location of your javascript files
  $HTML::Tested::JavaScript::Location = "/my-js-files";

=head1 DESCRIPTION

This is collection of HTML::Tested-style widgets which use JavaScript
functionality.

Please see individual modules for more information.

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested::JavaScript;
use HTML::Tested;

our $VERSION = '0.02';

=head1 VARIABLES

=head2 $Location

Set location of your javascript files. This is the src string in <script> HTML
tag. You probably need to alias it in your Apache configuration.

=cut
our $Location = "/html-tested-javascript";

sub Script_Include {
	return "<script src=\"$Location/serializer.js\"></script>\n"
}

1;

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Tested documentation.
L<HTML::Tested::JavaScript::Serializer|HTML::Tested::JavaScript::Serializer>.

=cut

