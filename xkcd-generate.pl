#!/usr/bin/perl
# Dave M <dave.nerd @ gmail>
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
use Tie::File;
use List::MoreUtils 'uniq';
use Getopt::Long;

# Pick one of these.  Some systems don't
# have the first one (like CentOS), so use
# the second one (MT::Auto).
# use Math::Random::Secure 'irand';    # faster than rand
use Math::Random::MT::Auto 'irand';
$| = 1;

my $VERSION = '0.0.6';
my @final_books;

# We'll keep this up here to ensure folks can change it if need be
my $book_location = '/usr/share/doc/xkcd-generate';

use Gtk3 '-init';
use Glib 'TRUE', 'FALSE';

my $window = Gtk3::Window->new;
$window->set_border_width( 10 );
$window->set_resizable( FALSE );
$window->signal_connect( destroy => sub { Gtk3->main_quit } );

my $box = Gtk3::Box->new( 'vertical', 0 );
$window->add( $box );

my $header = Gtk3::HeaderBar->new;
$header->set_title( 'xkcd phrase generator' );
$header->set_subtitle( " v $VERSION" );
$header->set_show_close_button( TRUE );
$header->set_decoration_layout( 'menu:minimize,close' );
$window->set_titlebar( $header );

my $about_btn = Gtk3::Button->new_from_icon_name( 'gtk-about', 3 );
$about_btn->signal_connect( 'clicked' => \&about );
$header->pack_start( $about_btn );
my $info_btn = Gtk3::Button->new_from_icon_name( 'gtk-help', 3 );
$info_btn->signal_connect( 'clicked' => \&explain );
$header->pack_start( $info_btn );

my $entry_1 = Gtk3::Entry->new;
my $entry_2 = Gtk3::Entry->new;
my $entry_3 = Gtk3::Entry->new;
my $entry_4 = Gtk3::Entry->new;
my $entry_5 = Gtk3::Entry->new;
$entry_5->set_width_chars( 40 );

my $use_numbers = 0;
my $use_special = 0;
my $use_neither = 1;
my $numbers_box = Gtk3::RadioButton->new_with_label( undef, 'Use numbers' );
$numbers_box->signal_connect( toggled => \&toggled, 1 );
my $special_box = Gtk3::RadioButton->new_with_label( $numbers_box,
    'Use special characters' );
$special_box->signal_connect( toggled => \&toggled, 2 );
my $neither_box
    = Gtk3::RadioButton->new_with_label( $numbers_box, 'Just words' );
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
$grid->set_column_homogeneous( FALSE );

$grid->attach( $entry_1, 0, 0, 1, 1 );
$grid->attach( $entry_2, 0, 1, 1, 1 );
$grid->attach( $entry_3, 0, 2, 1, 1 );
$grid->attach( $entry_4, 0, 3, 1, 1 );
$grid->attach( $entry_5, 0, 4, 1, 1 );

my $final_label = Gtk3::Entry->new;
$final_label->set_editable( FALSE );
$grid->attach( $final_label, 0, 5, 1, 1 );
my $final_sofar = '';

$grid->attach( $go_button,   0, 6, 1, 1 );
$grid->attach( $quit_button, 1, 6, 1, 1 );

$grid->attach( $numbers_box, 0, 7, 1, 1 );
$grid->attach( $special_box, 0, 8, 1, 1 );
$grid->attach( $neither_box, 0, 9, 1, 1 );

# Keyboard shortcuts
my $ui_info = get_ui_info();
my @entries = get_pseudo_keys();

my $actions = Gtk3::ActionGroup->new( 'Actions' );
$actions->add_actions( \@entries, undef );

my $ui = Gtk3::UIManager->new;
$ui->insert_action_group( $actions, 0 );

$window->add_accel_group( $ui->get_accel_group );
$ui->add_ui_from_string( $ui_info );

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
        my @books = glob "$book_location/*.txt";
        push( @books, $_ ) for ( glob "$book_location/*.dic" );
        my $filename;

        # Select book
        if ( $_ == 2 ) {
            my $rand_book = int( rand( scalar( @books ) ) );
            $filename = $books[ $rand_book ];
            push( @final_books, $filename );
        } else {
            $filename = "$book_location/nounlist.txt";
            push( @final_books, $filename );
        }

        # Words to skip
        my @skip = ( 'the', 'you', 'and' );

        # Open the random book
        # open( my $f, '<', $books[ $rand_book ] );

        my @array;
        use Fcntl 'O_RDONLY';
        tie @array, 'Tie::File', $filename, mode => O_RDONLY
            or die "Can't open $filename: $!\n";

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
            my $rand_num  = int( rand( $#words ) );
            my $rand_word = $words[ $rand_num ];

            $rand_word =~ s/[^a-zA-Z]//g;
            $rand_word = ucfirst( lc( $rand_word ) );

            # Skip it unless longer than 2 and shorter than 7 characters
            next if ( length( $rand_word ) < 3 );
            next if ( length( $rand_word ) > 8 );

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
        $irand = sanity( $irand );
        $entry_5->set_text( $irand );
        $final_sofar .= ' ' . $irand;
    } elsif ( $use_special ) {
        my $special_string = '';
        my @special = ( '!', '#', '$', '%', '^', '&' );
        for ( 0 .. 1 ) {
            $special_string .= $special[ int( rand( @special ) ) ];
        }
        $entry_5->set_text( $special_string );
        $final_sofar .= ' ' . $special_string;
    } elsif ( $use_neither ) {
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

sub sanity {
    my $bignum = shift;
    # For some reason, irand is returning huge numbers
    # despite telling it to use 100 + 1
    return substr( $bignum, 0, 2 );
}

sub get_ui_info {
    return "<ui>
  <menubar name='MenuBar'>
      <menuitem action='About'/>
      <menuitem action='Explain'/>
      <separator/>
      <menuitem action='Quit'/>
  </menubar>
</ui>";
}

sub get_pseudo_keys {
    #<<<
    my @entries = (
        [
           'About', undef,
           'About', '<control>A',
           undef, \&about,
           FALSE
        ],
        [
           'Explain', undef,
           'Explain', '<control>E',
           undef, \&explain,
           FALSE
        ],
        [
           'Quit', undef,
           'Quit', '<control>X',
           undef, sub { Gtk3->main_quit },
           FALSE
        ],
    );
    #>>>
    return @entries;
}

sub explain {
    my $images_dir = '/usr/share/pixmaps';
    my $icon       = "$images_dir/xkcd-password_strength.png";
    my $image      = Gtk3::Image->new_from_file( $icon );
    my $box        = Gtk3::Box->new( 'horizontal', 5 );
    $box->add( $image );

    my $dialogbox = Gtk3::Dialog->new;
    $dialogbox->set_title( 'xkcd comic explanation' );
    $dialogbox->get_content_area()->add( $box );
    $dialogbox->show_all;

    $dialogbox->run;
    $dialogbox->destroy;
}

sub about {
    my $dialog = Gtk3::AboutDialog->new;
    $dialog->set_title( 'About' );
    my $license
        = 'This is free software; you can redistribute it and/or'
        . ' modify it under the terms of either:'
        . ' a) the GNU GPL as published by the Free'
        . ' Software Foundation; version 1, or (at your option)'
        . ' any later version, or'
        . ' b) the "Artistic License".';
    $dialog->set_wrap_license( TRUE );

    my $images_dir = '/usr/share/pixmaps';
    my $icon       = "$images_dir/xkcd-5-dollar-wrench.png";
    my $pixbuf     = Gtk3::Gdk::Pixbuf->new_from_file( $icon );

    $dialog->set_logo( $pixbuf );
    $dialog->set_version( $VERSION );
    $dialog->set_license( $license );
    $dialog->set_wrap_license( TRUE );
    $dialog->set_website( 'https://github.com/dave-theunsub/xkcd-generate' );
    $dialog->set_website_label( 'Homepage' );
    $dialog->set_logo( $pixbuf );
    $dialog->set_program_name( 'xkcd generate' );
    $dialog->set_authors( [ 'Dave M', 'dave.nerd @ gmail' ] );
    $dialog->set_comments(
              'This program creates passphrases from novels to be used '
            . 'for authentication.  It is much easier to remember '
            . 'and harder to break short, non-sensical passphrases '
            . 'than to remember a long series of characters (which is '
            . 'also easier to break than the phrases).' );

    $dialog->run;
    $dialog->destroy;
}
