package ScaleFactory::Zabbix::Agent;

use strict;
use warnings;

use base qw( Net::Server::PreForkSimple );

use Log::Log4perl;
use Error qw(:try);
use Params::Validate qw(validate CODEREF SCALAR);

use ScaleFactory::Zabbix::Protocol::Packet;
use ScaleFactory::Zabbix::Error;
use ScaleFactory::Zabbix::Error::TimeOut;


my $actions = {};

sub register_handler {

    my $log = Log::Log4perl->get_logger( __PACKAGE__ );
    $log->trace( __PACKAGE__ . '->register_handler' );

    my $self = shift;

    my %args = validate( @_, {

        'parameter' => {
            type => SCALAR,
        },

        'sub' => {
            type => CODEREF,
        },

    } );

    if( exists( $actions->{ $args{ parameter } } ) ) {
        my $error = "Parameter '".$args{ parameter }."' already registered";
        $log->error( $error );
        throw ScaleFactory::Zabbix::Error( $error );
    }

    $log->info( "Registering handler for '".$args{ parameter }."'" );
    $actions->{ $args{ parameter } } = $args{ 'sub' };

}

sub process_request {

    my $log = Log::Log4perl->get_logger( __PACKAGE__ );

    my $self = shift;

    $log->trace( __PACKAGE__ . '->process_request()' );

    do {

        try {

            local $SIG{ 'ALRM' } = sub {
                throw ScaleFactory::Zabbix::Error::TimeOut;
            };
            my $timeout = 10; # TODO make this configurable

            my $previous_alarm = alarm( $timeout );

            my $req_packet = 
                ScaleFactory::Zabbix::Protocol::Packet::read_from_fh(
                    fh => *STDIN
                );

            my $request = $req_packet->get_data();
            chomp $request; # get rid of \n.  Should this be here, or elsewhere?
    
            $log->debug( "Request: $request" );
    
            my $parameter;
            my @parameter_args;
    
            if( $request =~ /^(.*)\[(.*)\]$/ ) {
    
                # Request has arguments.
                $parameter = $1;
                @parameter_args = split( /\s*,\s*/, $2 );
    
                $log->debug( "Parameter: $parameter" );
                foreach my $p ( @parameter_args ) {
                    $log->debug( "  Argument : $p" );
                }
    
            } else {
    
                # No arguments - use the request as-is.
                $parameter = $request;
                $log->debug( "Parameter: $parameter" );
                $log->debug( "(No arguments)" );
    
            }
    
            my $output = 'ZBX_NOTSUPPORTED';

            if( exists( $actions->{ $parameter } ) ) {
                $log->debug( "Matched handler for $parameter" );
                $output = $actions->{ $parameter }->( @parameter_args );
                $log->debug( "Output: $output" );
            } else {
                $log->debug( "No handler matching $parameter" );
            }
    
            my $res_packet = 
                ScaleFactory::Zabbix::Protocol::Packet::create_packet(
                    data    => $output,
                    version => $req_packet->version(),
                );
    
            print $res_packet->serialise();

            alarm( $timeout );

        }
        catch ScaleFactory::Zabbix::Error with {
            my $exception = shift;
            $log->error("Error caught in server: ".$exception->{'-text'});
            close( STDIN );
        }
        catch ScaleFactory::Zabbix::Error::TimeOut with {
            my $exception = shift;
            $log->info("Connection timed out");
            close( STDIN );
        }

    } while( ! eof( STDIN ) );



}

1;
