#!/usr/bin/perl -w

use Data::Dumper;

require 'backup_functions.pl';

our %mainConfig = do 'config.pl';
	
#print Data::Dumper->new([\%hostConfiguration],[qw(hash)])->Indent(3)->Quotekeys(0)->Dump;

my @files = <backup.d/*.pl>;

foreach $rsyncConfig (@files)
{
   	$rsyncConfig =~ /.*\.(\d+)$/;

   	my %hostConfiguration = do $rsyncConfig;

   	processHost(%hostConfiguration);
}