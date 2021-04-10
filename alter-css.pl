#!/usr/bin/perl
##############################################################################
##
##  ALTER-CSS compact CSS preprocessor
##  2021 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
use strict;

my %VARS;
my %BLOCKS;

my @data;
my $input_fname = shift;

load_css_file( $input_fname, \@data );

while( @data )
  {
  my $line = shift @data;
  
  next if line_set_var( $line );
  next if line_set_block( $line, \@data );
  next if line_print_block( $line );
  
  print update_vars( $line ) . "\n";
  }

sub load_css_file
{
  my $fname = shift;
  my $ar    = shift; # result array ref

  open( my $if, '<', $fname );
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

  $VARS{ uc $1 } = [ $2, split /\s+/, $2 ];

#print STDERR "DEBUG: SET VAR: $1 -- $2\n";

  return 1;
}

sub line_set_block
{
  my $line = shift;
  my $data = shift;

#print STDERR ">>>>>> [$line]\n";
  
  return undef unless $line =~ /^\$\$([a-z_0-9-]+)/i;
  my $name = uc $1;
  my @block;

  while( @$data and $data->[ 0 ] =~ /^\s+\S/ )
    {
    push @block, shift @$data;
    }
  
  $BLOCKS{ $name } = \@block;

#print STDERR "DEBUG: SET BLOCK: $name -- \n" . join( "\n", @block ) . "\n^^^\n";

  return 1;
}

sub line_print_block
{
  my $line = shift;
  return undef unless $line =~ /^\s+\$\$([a-z_0-9-]+)(\s+(.*?)\s*)?$/i;
  my $name = uc $1;
  my $args =    update_vars( $3 );

#print STDERR "DEBUG: GET BLOCK: $name -- $args\n";

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

  $line =~ s/\$([a-z_0-9-]+)(\.(\d+))?/__get_var( $1, $3, $args )/gie;
  
  return $line;
}

sub __get_var
{
  my $var_name = uc shift;
  my $var_idx  =    shift || 0;
  my $args     =    shift || [];

#print STDERR "DEBUG: GET VAR: $var_name -- $var_idx (@$args)\n";
  if( $var_name =~ /^\d+$/ )
    {
    return $args->[ $var_name ];
    }

  if( exists $VARS{ $var_name } )
    {
    return $VARS{ $var_name }[ $var_idx ];
    }
  else
    {
    # TODO: warning: unknown var name. error? fatal?
    return undef;
    }  
}
