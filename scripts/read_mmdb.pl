#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;

my $ip = shift @ARGV or die 'Usage: perl examples/02-reader.pl [ip_address]';

my $asn_db = shift @ARGV or die 'No data base found';

my $reader = MaxMind::DB::Reader->new( file => $asn_db );

say 'Description: ' . $reader->metadata->{description}->{en};

my $record = $reader->record_for_address( $ip );
say np $record;
