package ScaleFactory::Zabbix::Protocol::Packet::v1;

use strict;
use warnings;

use Params::Validate qw(validate HANDLE);

sub read_from_fh {

    my $log = Log::Log4perl->get_logger(__PACKAGE__);

    $log->trace(__PACKAGE__.'::read_from_fh()');

    my %args = validate( @_, {

        # fh must be a file handle
        fh => {
            type => HANDLE,
        },

    } );

    my $data;
    my $bytes_read = sysread( $args{fh}, $data, 8 );

    if( $bytes_read != 8 ) {
        my $error = "Expected 8 bytes but read $bytes_read";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    my ( $length1, $length2 ) = unpack( "VV", $data );

    if( $length2 ) {
        my $error = "The zabbix protocol requires that the length ".
            "field be 64 bits, however this server imeplementation ".
            "can only cope with 32 bit lengths.  We find it ".
            "surprising that you've made a request this long and ".
            "gracefully decline to service it";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    $log->debug( "Request length: $length1" );

    $bytes_read = sysread( $args{fh}, $data, $length1 );
    if( $bytes_read != $length1 ) {
        my $error = "Expected $length1 bytes but read $bytes_read";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    $log->debug( "Read: $data" );

    return ScaleFactory::Zabbix::Protocol::Packet::v1->new( data => $data );

}

sub new {

    my $class = shift;

    my $log = Log::Log4perl->get_logger(__PACKAGE__);
    $log->trace(__PACKAGE__.'->new()');

    my %args = validate( @_, {
        data => 1,
    } );

    my $self = bless {}, $class;

    $self->{ data } = $args{data};

    return $self;
}

sub version {

    my $log = Log::Log4perl->get_logger(__PACKAGE__);
    $log->trace(__PACKAGE__.'->version()');

    return 1;
}

sub get_data {

    my $log = Log::Log4perl->get_logger(__PACKAGE__);
    $log->trace(__PACKAGE__.'->get_data()');

    return $_[0]->{ data };
}

sub serialise {

    my $log = Log::Log4perl->get_logger(__PACKAGE__);
    $log->trace(__PACKAGE__.'->serialise()');

   my $self = shift;

   my $output = $self->{ data }."\n";

   return 'ZBXD' .
          pack( "C", $self->version() ).
          pack( "V", length( $output ) ).   # 64 bit cheat. Send 32bit length
          pack( "V", 0 ).                   #  then an empty 32 bits.
          $output;                          # TODO (should really check length)

}

1;
