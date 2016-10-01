#!/usr/bin/env perl

use v5.10.0;
use warnings;
use strict;

sub isInitialized{
	$MAEDIR=$ENV{'DIRMAE'};
	if ("$DIRMAE"){
		return 1;	
	}else{
		return 0;
	}
	
}

sub isAlreadyRunning{
	$counter = `ps -a | grep -c 'Listep'`;
	#$counterIfIsNotRunning = 2; #Linux
	$counterIfIsNotRunning = 3; #MAC
	if($counter > $counterIfIsNotRunning){
		return 1;
	}else{
		return 0;
	}

}
