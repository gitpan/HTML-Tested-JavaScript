use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'HTML::Tested::JavaScript',
	VERSION_FROM => 'lib/HTML/Tested/JavaScript.pm', # finds \$VERSION
	AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
	ABSTRACT     => 'HTML::Tested JavaScript helpers',
	PREREQ_PM    => { 'Test::Simple' => 0.44,
	    		'HTML::Tested' => 0.29,
	    		'Mozilla::Mechanize::GUITester' => 0.12,
			'File::Slurp' => '',
			'HTTP::Daemon' => '',
			'HTTP::Request::Params' => '',
			'Mozilla::SourceViewer' => '0.05'
	},
);

package MY;

sub install {
	my $res = shift->SUPER::install(@_);
	$res =~ s/(\$\(DEST[^\\]*MAN1DIR\))([^\$]+)/$1 $2javascript \$(SITEPREFIX)\/share\/libhtml-tested-javascript-perl \\\n/g;
	return $res;
}

