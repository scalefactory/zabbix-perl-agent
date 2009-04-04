#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Log::Log4perl qw(:easy);
Log::Log4perl::init('log4perl.conf') or die($!);

use ScaleFactory::Zabbix::Agent;

my $agent = ScaleFactory::Zabbix::Agent->new();

$agent->register_handler( 
    'parameter' => 'version',
    'sub'       => sub {
        return 'Scale Factory Zabbix agent (perl) 0.01';
    },
);

$agent->register_handler(
    'parameter' => 'echo',
    'sub'       => sub {
        return 'Echoing: ' . join( ',', map { "'$_'" } @_ );
    },
);

$agent->run(
    port        => 10050,
    max_servers => 5,
);
