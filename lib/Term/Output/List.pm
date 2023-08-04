package Term::Output::List 0.02;
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';

use Module::Load 'load';

=head1 NAME

Term::Output::List - output an updateable list of ongoing jobs

=head1 SYNOPSIS

    my $printer = Term::Output::List->new();
    my @ongoing_tasks = ...;
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

sub detect_terminal_type($os = $^O) {
	if( $os eq 'MSWin32' ) {
		require Win32::Console;
		if( Win32::Console->Mode & 0x0004 ) { #ENABLE_VIRTUAL_TERMINAL_PROCESSING 
			return 'ansi';
		} else {
			return 'win32'
		}
	} else {
		return 'ansi';
	}
}

sub new($class,%args) {
	my $ttype = detect_terminal_type();
	
	my $impl = 'Term::Output::List::ANSI';
	if( $ttype eq 'win32' ) {
	    $impl = 'Term::Output::List::Win32';
	}
	load $impl;
	return $impl->new( %args )
}

1;