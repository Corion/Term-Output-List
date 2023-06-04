package Term::Output::List;
use strict;
use warnings;
use Moo 2;
use Term::Cap;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

# We should use termcap for scrolling up
# We should have Win32 console support (maybe just Win32::Console::ANSI ?)
# -> Win32::Console->Mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING != 0 -> VT sequences
# -> otherwise scroll_up via Win32::Console->Cursor()
# We should provide a graceful fallback for systems without scroll-up facilities
#    like a pipe
# The API doesn't look great - do we want multiple instances at all? We can't
#   handle them anyway, in a sensible way

=head1 NAME

Term::Output::List - output an updateable list of ongoing jobs

=head1 SYNOPSIS

    my $printer = Term::Output::List->new();
    my @ongoing_tasks = ...;
    $printer->output_list(@ongoing_tasks);

    $printer->output_permanent("Frobnicated gizmos"); # appears above the list

=cut

has '_last_lines' => (
    is => 'rw',
);

=head1 MEMBERS

=head2 C<< fh >>

Filehandle used for output. Default is C<< STDOUT >>.

=cut

has 'fh' => (
    is => 'lazy',
    default => sub { \*STDOUT },
);

has 'terminfo' => (
    is => 'lazy',
    default => sub { Term::Cap->Tgetent({ OSPEED => 112000 })},
);

has 'term_scroll_up' => (
    is => 'lazy',
    default => sub { $_[0]->terminfo->Tputs('UP') },
);

has 'term_clear_eol' => (
    is => 'lazy',
    default => sub { $_[0]->terminfo->Tputs('ce') },
);

has 'interactive' => (
    is => 'lazy',
    default => sub { -t $_[0]->fh },
);

=head1 METHODS

=head2 C<< Term::Output::List->new() >>

=cut

=head2 C<< ->scroll_up >>

Helper method to place the cursor at the top of the updateable list.

=cut

sub scroll_up( $self, $count=$self->_last_lines ) {
    if( !$count) {
    } else {
        # Overwrite the number of lines we printed last time
        print { $self->fh } "\r" . sprintf $self->term_scroll_up(), ${count};
        #sleep 1;
    };
}

=head2 C<<->output_permanent>>

  $o->output_permanent("Frobnicated 3 items for job 2");
  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that should go on the permanent record. It is expected to
output the (remaining) list of ongoing jobs after that.

=cut

sub output_permanent( $self, @items ) {
    my $total = $self->_last_lines // 0;
    if( $self->interactive ) {
        $self->scroll_up();
    }
    my $clear_eol = $self->term_clear_eol;
    if( @items ) {
        print { $self->fh } join("$clear_eol\n", @items)."$clear_eol\n";
    };
    #sleep 1;

    if( $self->interactive ) {
        my $blank = $total - @items;
        if( $blank > 0 ) {
            print { $self->fh } "$clear_eol\n"x ($blank);
            $self->scroll_up( $blank );
        }
        $self->fresh_output();
    }
}

=head2 C<<->output_list @items>>

  $o->output_list("Frobnicating 9 items for job 1",
                  "Frobnicating 2 items for job 3",
  );

Outputs items that can be updated later, as long as no intervening C<print>
or C<warn> output has happened. If you want to output lines that should
not be overwritten later, see C<</->output_permanent>>

=cut

sub output_list( $self, @items ) {
    if( $self->interactive ) {
        $self->output_permanent(@items);
        #sleep 1;
        $self->_last_lines( 0+@items);
    }
}

=head2 C<<->fresh_output >>

  $o->fresh_output();

Helper subroutine to make all items from the last output list remain as is.

For compatibility between output to a terminal and output without a terminal,
you should use C<< ->output_permanent >> for things that should be permanent
instead.

=cut

sub fresh_output( $self ) {
    $self->_last_lines( 0 );
}

1;
