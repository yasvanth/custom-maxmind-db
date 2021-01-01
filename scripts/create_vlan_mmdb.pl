#!/usr/bin/env perl

use strict;
use warnings;
use YAML::XS 'LoadFile';
use Data::Dumper;
use feature qw( say );
use local::lib 'local';
use Net::Works::Network;
use MaxMind::DB::Writer::Tree;



#####
# This is to create mmdb with VLAN description to add VLAN entries from sFLOW
#   ---- experimental : need an update with filter flugin to add custom tags. ---
#####

# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

#my %types = (
#    vlan_id         => 'utf8_string',
#    vlan_description   => 'utf8_string',
#    
#);

###
# Using autonomuse_system_number and automonus_system_organization instead of vlan_id and vlan_description 
# becaue logstash-geo-IP filter pluging dosent suppot custom attibutes.
# https://github.com/logstash-plugins/logstash-filter-geoip/blob/ed365076d59733325051cb52c31d05c1614384a9/src/main/java/org/logstash/filters/GeoIPFilter.java#L47

# Fields can be renamed at using logstash after geoip lookup. 
#
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
        { en => 'Service Network VLAN database', },

    # "ip_version" can be either 4 or 6
    # Mentioning IP version as 6 will support IPv4 too
    ip_version => 6,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 24,
);

############
# YB - Modifyed the code to create mmdb from yaml file
###########
my $config = LoadFile('../files/custom_vlan_input.yml');

# Perl hash to store YAML content
my %address_of_network;

my $file_name = 'Custom-Service-Network-VLAN.mmdb';
# Output file for mmdb creation

my $output_file = '../files/output/Database/' . $file_name; 

for (keys %{$config}){
  my @services_network; #network might be an array
  my $vlan_description;
  my $vlan_id;
  my $vlan_network;

  $vlan_id = $_;
    say "VLAN ID $vlan_id\n";
    for (keys %{$config->{$vlan_id}}) {
      $vlan_description = $config->{$vlan_id}->{description};
      if ( defined ($config->{$vlan_id}->{network}) ){
        @services_network = @{$config->{$vlan_id}->{network}};
        #say " The Network : @services_network\n";
        say " Desc : $vlan_description\n";
      }
    }
    if (@services_network){
      for (@services_network){
        $vlan_network = $_;
        %address_of_network = (
            $vlan_network => {
               autonomous_system_number => $vlan_id,
               autonomous_system_organization => $vlan_description,
            }
        );

        for my $address ( keys %address_of_network ) {
             my $network = Net::Works::Network->new_from_string( string => $address );
#             print "the '$network' and the values are ".Dumper($address_of_network{$address})." \n";
             $tree->insert_network( $network, $address_of_network{$address} );
          }
      }
    }
}


# Write the database to disk.
open my $fh, '>:raw', $output_file;
$tree->write_tree( $fh );
close $fh;

say "$file_name has now been created"
