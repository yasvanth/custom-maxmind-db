# custom-maxmind-db


This repo contains the script to create ASN (Autonomous System Number) and VLAN database in [maxmind db format](https://dev.maxmind.com/geoip/geoip2/geolite2). <br> 
Logstash geoip-filter plugin does [support](https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html#_supported_databases) the maxmind format to result in fast data search. 


#### Prerequisites:
*  perl
*  libmaxminddb <br>
    `apt install libmaxminddb-dev`
*  cpanminus <br>
    `curl -L https://cpanmin.us | perl - App::cpanminus`
*  CPAN Modules <br>
    `cpanm Devel::Refcount MaxMind::DB::Reader::XS MaxMind::DB::Writer::Tree Net::Works::Network GeoIP2 Data::Printer`
    
   on mac OSX <br>
    `ARCHFLAGS="-arch x86_64" cpanm MaxMind::DB::Writer::Tree Net::Works::Network`
