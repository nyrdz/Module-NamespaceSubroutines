package Module::NamespaceSubroutines;

use 5.014;
use strict;
use warnings;
use attributes;
use File::Find ();

=head1 NAME

Module::NamespaceSubroutines - Finds subroutines in namespace (attributes included)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Finds subroutines in namespace (attributes included).

    use Module::NamespaceSubroutines;

	# Mojolicious routing example
	my $r = $self->routes;
    Module::NamespaceSubroutines::find("My::App::Controller", sub {
		my ($module, $subname, $subref, $attrs) = @_;
		my $method;
		$method = 'get'  if $attrs->{GET};
		$method = 'post' if $attrs->{POST};
		my $path = '/' . join('/', map { lc $_ } @$module) . $subname;
		$r->$method($path)->to( controller => join('::', @$module), action => $subname );
	});

=head1 SUBROUTINES/METHODS

=head2 find

=cut

my %skip = (
	MODIFY_CODE_ATTRIBUTES => 1,
	FETCH_CODE_ATTRIBUTES  => 1,
);

sub find {
	my ($ns, $cb) = @_;
	my $ns2 = $ns =~ s|::|/|gr; # 'My::App::Controller' -> 'My/App/Controller'

	my @modules;
	foreach my $path (@INC) {
		File::Find::find(sub {
			return unless /\.pm$/;
			my $name = $File::Find::name =~ s/$path\///r;
			return unless $name =~ /^$ns2/;
			push @modules, [$name, $File::Find::name];
		}, $path);
	}

	foreach my $m (@modules) {
		my ($name, $path) = @$m;
		my @a = split( '/', $name );    # 'Data/Dumper.pm' -> qw(Data Dumper.pm)
		pop @a;                         # qw(Data)
		my $namespace = join( '/', @a );     # 'Data'
		next unless $namespace =~ /^$ns2/;    # 'My/App/Controller/Users.pm', 'My/App/Controller/Inventory.pm', etc.
		require $path unless defined $INC{$name};
		my $module = $name;             # 'My/App/Controller/Users.pm'
		$module =~ s/\.pm$//;           # 'My/App/Controller/Users'
		$module =~ s|/|::|g;            # 'My::App::Controller::Users'
		$module .= '::';                # 'My::App::Controller::Users::'
		my $table = '%' . $module;      # '%My::App::Controller::Users::'
		my $subroutines;
		## no critic (BuiltinFunctions::ProhibitStringyEval) [Don't know how to access symbol table hash with string module name]
		eval <<~PERL;
		my \@symbols;
		foreach my \$entry (keys $table) {
			next unless defined &{'$module' . \$entry};
			push \@symbols, \$entry;
		}
		\$subroutines = join('|', \@symbols);
		PERL
		$module =~ s/^$ns\::(.+)::$/$1/; # 'My::App::Controller::Users::' -> 'Users'
		my @subroutines = split('\|', $subroutines);
		my %subroutines;
		open my $fh, '<', $path;
		while(my $line = <$fh>) {
			next unless $line =~ /^sub\s+(\w+)[\:\(\s]/;
			$subroutines{$1} = 1;
		}
		close($fh);
		foreach my $subroutine (@subroutines) {
			next if $skip{$subroutine};
			next unless $subroutines{$subroutine};
			my $name = join('::', $ns, $module, $subroutine);
			my $ref = \&$name;
			my %attrs = map {$_ => 1} attributes::get(\&$name);
			$cb->([split('::', $module)], $subroutine, $ref, \%attrs);
		}
	}
}

=head1 AUTHOR

José Manuel Rodríguez D., C<< <jose93rd at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-namespacesubroutines at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-NamespaceSubroutines>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::NamespaceSubroutines


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-NamespaceSubroutines>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Module-NamespaceSubroutines>

=item * Search CPAN

L<https://metacpan.org/release/Module-NamespaceSubroutines>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by José Manuel Rodríguez D.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Module::NamespaceSubroutines
