package ScaleFactory::Zabbix::Protocol::Packet;

use strict;
use warnings;

use Params::Validate qw(validate HANDLE SCALAR);
use Error;
use Log::Log4perl;

use ScaleFactory::Zabbix::Protocol::Packet::v1;
use ScaleFactory::Zabbix::Error;

my $versions = {

    1 => 'ScaleFactory::Zabbix::Protocol::Packet::v1',

};

sub read_from_fh {

    my $log = Log::Log4perl->get_logger( __PACKAGE__ );

    $log->trace( __PACKAGE__ . '::read_from_fh()');

    my %args = validate( @_, {

        # fh must be a file handle
        fh => { 
            type => HANDLE,
        },

    } );

    my $data;
    my $bytes_read = sysread( $args{fh}, $data, 5 );

    if( $bytes_read != 5 ) {
        my $error = "Expected 5 bytes but read $bytes_read";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    my( $header, $version ) = unpack( "A4C", $data );

    $log->debug( "Got header of '$header'" );
    $log->debug( "Got version $version" );

    if( $header ne 'ZBXD' ) {
        my $error = "Expected header of 'ZBXD' but got '$header'";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    if( !exists( $versions->{ $version } ) ) {
        my $error = "Unsupported protocol version $version";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    my $handler = $versions->{ $version }.'::read_from_fh';

    # Ugly!
    return &{\&$handler}( @_ );

}

sub create_packet {

    my $log = Log::Log4perl->get_logger( __PACKAGE__ );

    $log->trace( __PACKAGE__ . '::create_packet()' );

    my %args = validate( @_, {

        version => {
            type  => SCALAR,
            regex => qr/^\d+$/,
        },

        data => {
            type => SCALAR,
        }

    } );

    if( !exists( $versions->{ $args{ version } } ) ) {
        my $error = "Unsupported protocol version ".$args{ version };
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    my $packet_class = $versions->{ $args{ version } };

    return $packet_class->new( data => $args{ data } );

}



1;
