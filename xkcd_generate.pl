#!/usr/bin/perl
# davem @ davem.cloud
#
# xkcd password, (c) 2016 -
# 0.01 - initial release
# 0.02 - minor improvements/fixes
# 0.03 - compatible with both Fedora and CentOS (Math::Random lines)
#
# Sources:
# https://xkcd.com/936/
# Project Gutenberg: https://www.gutenberg.org
# perl-List-MoreUtils
# perl-Math-Random-Secure
# perl-Math-Random-Auto
# perl-Getopt-Long

use strict;
use warnings;
use Modern::Perl;
use Tie::File;
use List::MoreUtils 'uniq';
use Getopt::Long;

# Pick one of these.  Some systems don't
# have the first one (like CentOS), so use
# the second one (MT::Auto).
# use Math::Random::Secure 'irand';    # faster than rand
# use Math::Random::MT::Auto 'irand';
$| = 1;

my $VERSION = '0.0.3';

use Gtk3 '-init';
use Glib 'TRUE', 'FALSE';

my $window = Gtk3::Window->new;
$window->set_title( 'xkcd Phrase Generator' . "v $VERSION" );
$window->set_border_width( 15 );
# $window->set_default_size( 250, 250 );
$window->signal_connect( destroy => sub { Gtk3->main_quit } );

my @final_books;

my $box = Gtk3::Box->new( 'vertical', 5 );
$window->add( $box );

my $entry_1 = Gtk3::Entry->new;
my $entry_2 = Gtk3::Entry->new;
my $entry_3 = Gtk3::Entry->new;
my $entry_4 = Gtk3::Entry->new;
my $entry_5 = Gtk3::Entry->new;

my $use_numbers = 0;
my $use_special = 0;
my $use_neither = 1;
my $numbers_box = Gtk3::RadioButton->new_with_label( undef, 'Use numbers' );
$numbers_box->signal_connect( toggled => \&toggled, 1 );
my $special_box = Gtk3::RadioButton->new_with_label( $numbers_box,
    'Use special characters' );
$special_box->signal_connect( toggled => \&toggled, 2 );
my $neither_box
    = Gtk3::RadioButton->new_with_label( $numbers_box, 'Use neither' );
$neither_box->signal_connect( toggled => \&toggled, 3 );
$neither_box->set_active( TRUE );
my $go_button = Gtk3::Button->new( 'Generate' );
$go_button->signal_connect(
    clicked => sub {
        clear_all();
        generate();
    }
);
my $quit_button = Gtk3::Button->new( 'Quit' );
$quit_button->signal_connect( clicked => sub { Gtk3->main_quit } );

my $grid = Gtk3::Grid->new;
$box->pack_start( $grid, TRUE, TRUE, 5 );
$grid->set_column_spacing( 5 );
$grid->set_row_spacing( 15 );
$grid->set_column_homogeneous( TRUE );

$grid->attach( $numbers_box, 0, 0, 1, 1 );
$grid->attach( $special_box, 1, 0, 1, 1 );
$grid->attach( $neither_box, 2, 0, 1, 1 );
$grid->attach( $go_button,   3, 0, 1, 1 );
$grid->attach( $quit_button, 4, 0, 1, 1 );

$grid->attach( $entry_1, 0, 1, 1, 1 );
$grid->attach( $entry_2, 1, 1, 1, 1 );
$grid->attach( $entry_3, 2, 1, 1, 1 );
$grid->attach( $entry_4, 3, 1, 1, 1 );
$grid->attach( $entry_5, 4, 1, 1, 1 );

my $final_label = Gtk3::Entry->new;
$final_label->set_editable( FALSE );
$grid->attach( $final_label, 0, 2, 2, 1 );
my $final_sofar = '';

$window->show_all;
Gtk3->main();

sub clear_all {
    $entry_1->set_text( '' );
    $entry_2->set_text( '' );
    $entry_3->set_text( '' );
    $entry_4->set_text( '' );
    $entry_5->set_text( '' );
    $final_label->set_text( '' );
    $final_sofar = '';
}

sub generate {
    for ( 0 .. 3 ) {
        my @books = glob "*.txt";
        my $filename;

        # Select book
        if ( $_ == 2 ) {
            my $rand_book = int( rand( scalar( @books ) ) );
            $filename = $books[ $rand_book ];
            push( @final_books, $filename );
            warn "added $filename to sources\n";
        } else {
            $filename = 'nounlist.txt';
            push( @final_books, $filename );
        }

        # Words to skip
        my @skip = ( 'the', 'you', 'and' );
        warn "skipping words ", join( ',', @skip ), "\n";

        # Open the random book
        # open( my $f, '<', $books[ $rand_book ] );

        my @array;
        tie @array, 'Tie::File', $filename
            or die "Can't open $filename: $!\n";

        warn "using $filename which has ", scalar @array, " lines\n";

        while ( 1 ) {
            # Pick a random line from the book ($filename)
            my $rand_line = int( rand( $#array ) );
            my $line      = $array[ $rand_line ];
            # Skip it if it's blank
            next if ( $line =~ /^\s*$/ );

            # Put all the words of the line in an array (@words)
            my @words = split( / /, $line );
            @words = grep {
                my $foo = $_;
                not grep { $foo =~ /$_/i } @skip
            } @words;
            @words = uniq( @words );
            next unless ( @words );

            # Pick a random word from the random line
            my $rand_num = int( rand( $#words ) );
            # warn "rand_num = >$rand_num<\n";
            my $rand_word = $words[ $rand_num ];
            # Skip it unless longer than 2 and shorter than 7 characters
            next if ( length( $rand_word ) < 3 );
            next if ( length( $rand_word ) > 8 );
            warn "selected word $rand_word\n";

            $rand_word =~ s/[^a-zA-Z]//g;
            $rand_word = ucfirst( lc( $rand_word ) );
            # print ucfirst( $rand_word ), " ";
            if ( $_ == 0 ) {
                $entry_1->set_text( $rand_word );
            } elsif ( $_ == 1 ) {
                $entry_2->set_text( $rand_word );
            } elsif ( $_ == 2 ) {
                $entry_3->set_text( $rand_word );
            } elsif ( $_ == 3 ) {
                $entry_4->set_text( $rand_word );
            }
            $final_sofar .= ' ' . $rand_word;
            last;
        }
    }
    if ( $use_numbers ) {
        my $irand = irand( 100 ) + 1;
        warn "adding number $irand\n";
        $entry_5->set_text( $irand );
        $final_sofar .= ' ' . $irand;
    } elsif ( $use_special ) {
        my $special_string = '';
        my @special = ( '!', '#', '$', '%', '^', '&' );
        for ( 0 .. 1 ) {
            $special_string .= $special[ int( rand( @special ) ) ];
            warn "adding character $special_string\n";
        }
        $entry_5->set_text( $special_string );
        $final_sofar .= ' ' . $special_string;
    } elsif ( $use_neither ) {
        warn "not using numbers or special characters\n";
        $entry_5->set_text( '' );
    }
    $final_label->set_text( $final_sofar );
}

sub toggled {
    my ( $button, $state ) = @_;

    if ( $state == 1 ) {
        $use_numbers = 1;
        $use_special = 0;
        $use_neither = 0;
    } elsif ( $state == 2 ) {
        $use_numbers = 0;
        $use_special = 1;
        $use_neither = 0;
    } elsif ( $state == 3 ) {
        $use_numbers = 0;
        $use_special = 0;
        $use_neither = 1;
    }
}
