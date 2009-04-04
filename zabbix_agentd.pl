#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($TRACE);

use ScaleFactory::Zabbix::Agent;

ScaleFactory::Zabbix::Agent->run(
    port        => 10050,
    max_servers => 5,
);
