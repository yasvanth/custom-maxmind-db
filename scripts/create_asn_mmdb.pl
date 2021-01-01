#!/usr/bin/env perl

use strict;
use warnings;
use YAML::XS 'LoadFile';
use Data::Dumper;
use feature qw( say );
use local::lib 'local';
use Net::Works::Network;
use MaxMind::DB::Writer::Tree;


# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %types = (
    autonomous_system_number         => 'uint32',
    autonomous_system_organization   => 'utf8_string',
);


my $tree = MaxMind::DB::Writer::Tree->new(

    # "database_type" is some arbitrary string describing the database.  At
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.
    database_type => 'GeoLite2-ASN',

    languages => ['en'],

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.
    description =>
        { en => 'Custom Clinet ASN Database', },

    # "ip_version" can be either 4 or 6
    ip_version => 4,

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },
);

############
# Modifyed the code to read data from input file 
#   and to create DB
###########
my $config = LoadFile('../files/input/custom_asn_input.yml');

# Perl hash to store YAML content
my %address_of_network;

my $file_name = 'custom-ClientASN.mmdb';
# Output file for mmdb creation

my $output_file = '../files/output/Database/' . $file_name; 

for (keys %{$config}){
  my @org_network; #network might be an array
  my $org_asn;
  my $org_name;
  my $org_network;

  $org_name = $_;
    #say "Org Name $org_name\n";
    for (keys %{$config->{$org_name}}) {
      $org_asn = $config->{$org_name}->{asn};
      if ( defined ($config->{$org_name}->{network})){
        @org_network = @{$config->{$org_name}->{network}};
        #say " The Network : @org_network\n";
      }
    }
    if (@org_network){
      for (@org_network){
        $org_network = $_;
        #print "$org_name\'s asn is \"$org_asn\" and has following networks: $org_network";
        %address_of_network = (
            $org_network => {
               autonomous_system_number => $org_asn,
               autonomous_system_organization => $org_name,
            }
        );

        #my @networks = keys %address_of_network;
        for my $address ( keys %address_of_network ) {
        #  for my $network (@networks) {
#             print "the '$network' and the values are $address_of_network{$network} \n";
             my $network = Net::Works::Network->new_from_string( string => $address );
             $tree->insert_network( $network, $address_of_network{$address} );
          }
      }
    }
}


# Write the database to disk.
print Dumper($tree);
open my $fh, '>:raw', $output_file;
$tree->write_tree( $fh );
close $fh;

say "$file_name has now been created"
