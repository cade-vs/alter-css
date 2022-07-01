#!/usr/bin/perl
##############################################################################
##
##  ALTER-CSS compact CSS preprocessor
##  2021-2022 (c) Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##
##  LICENSE: GPLv2
##
##############################################################################
use strict;

my $DEBUG;

my %VARS;
my %BLOCKS;
my $HEXES = '0123456789ABCDEF';

my $VERSION = '1.4';

$VARS{ 'ALTER_CSS_GEN_WARNING' } = [ "THIS FILE IS GENERATED! PLEASE, DO NOT MODIFY!" ];
$VARS{ 'ALTER_CSS_GEN_TIME'    } = [ scalar localtime( time() ) ];

our $help_text = <<END;
ALTER-CSS version $VERSION 2021-2022 (c) Vladi Belperchinov <cade\@noxrun.com>
usage: 
    $0 <options> input-file.css > result-file.css
options:
    -d        -- increase DEBUG level (can be used multiple times)
    -i path   -- add include path(s) to search for css templates
                 (can be used multiple times, '.' is always searched) 
    --        -- end of options
END

if( @ARGV == 0 )
  {
  print $help_text;
  exit;
  }

my @inc = ( '.' );

our @args;
while( @ARGV )
  {
  $_ = shift;
  if( /^--+$/io )
    {
    push @args, @ARGV;
    last;
    }
  if( /^-i/ )
    {
    push @inc, shift;
    print "added include path [$inc[-1]] \n";
    next;
    }
  if( /^-d/ )
    {
    $DEBUG++;
    print "option: debug level raised, now is [$DEBUG] \n";
    next;
    }
  if( /^(--?h(elp)?|help)$/io )
    {
    print $help_text;
    exit;
    }
  push @args, $_;
  }

my @data;
my $input_fname = shift @args;

load_css_file( $input_fname, \@data );

while( @data )
  {
  my $line = shift @data;
  
  next if $line =~ /^\s*\/\*\$/; # alter-css comments   /*$ ... */
  next if line_set_var( $line );
  next if line_set_block( $line, \@data );
  next if line_print_block( $line );
  
  print update_vars( $line ) . "\n";
  }

sub load_css_file
{
  my $fname = shift;
  my $ar    = shift; # result array ref

  my $ffname;
  for( @inc )
    {
    $ffname = "$_/$fname";
    last if -e $ffname;
    }
  die "error: cannot find file [$fname] in search paths [@inc] output file may be broken!\n" unless -e $ffname;  

  open( my $if, '<', $ffname ) or die "error: cannot read file [$ffname] output file may be broken!\n";
  while( <$if> )
    {
    chomp;
    load_css_file( $1, $ar ) and next if /\$\$\$(\S+)/;
    push @$ar, $_;
    }
  close( $if );  
  return 1;
}

sub line_set_var
{
  my $line = shift;

  return undef unless $line =~ /^\$([a-z_0-9-]+)\s+(.*?)\s*$/i;
  my $args = update_vars( $2 );

  $VARS{ fix_var_name( $1 ) } = [ $args, split /\s+/, $args ];

  return 1;
}

sub line_set_block
{
  my $line = shift;
  my $data = shift;

  return undef unless $line =~ /^\$\$([a-z_0-9-]+)/i;
  my $name = fix_var_name( $1 );
  my @block;

  while( @$data and $data->[ 0 ] =~ /^\s+\S/ )
    {
    push @block, shift @$data;
    }
  
  $BLOCKS{ $name } = \@block;

  return 1;
}

sub line_print_block
{
  my $line = shift;
  return undef unless $line =~ /^\s+\$\$([a-z_0-9-]+)(\s+(.*?)\s*)?$/i;
  my $name = fix_var_name( $1 );
  my $args = update_vars( $3 );

  if( exists $BLOCKS{ $name } )
    {
    my @args = ( $args, split /\s+/, $args );
    print update_vars( $_, \@args ) . "\n" for @{ $BLOCKS{ $name } };
    }
  else
    {
    # TODO: warning: unknown block name. error? fatal?
    }  

  return 1;
}

sub update_vars
{
  my $line = shift;
  my $args = shift;

  $line =~ s/\$([a-z_0-9-]+)(\.(\d+))?(\/([\+\-]\d+))?/__get_var( $1, $3, $args, $5 )/gie;
  $line =~ s/#([0-9A-F]{3,6})([\+\-])(\d+)/__precolor( $1, $2, $3 )/gie;
  return $line;
}

sub fix_var_name
{
  my $name = shift;
  $name =~ s/-/_/g;
  return uc $name;
}

sub __get_var
{
  my $var_name = fix_var_name( shift );
  my $var_idx  =    shift || 0;
  my $args     =    shift || [];
  my $bump     =    shift;

  return $args->[ $var_name ] . $bump           if $var_name =~ /^\d+$/;
  return $VARS{ $var_name }[ $var_idx ] . $bump if exists $VARS{ $var_name };
  return undef; # TODO: warning: unknown var name. error? fatal?
}

sub __precolor
{
  my $color  = shift;
  my $updown = shift;
  my $scale  = shift;
  
  return '#' . join( '', map { __precolor_fix( $_, $updown, $scale ) } split //, uc $color );
}

sub __precolor_fix
{
  my $color  = shift;
  my $updown = shift;
  my $scale  = shift;

  my $c = index( $HEXES, $color );
  $c = $updown eq '+' ? $c + $scale : $c - $scale;
  $c =  0 if $c < 0;
  $c = 15 if $c > 15;
  return substr( $HEXES, $c, 1 );
}
