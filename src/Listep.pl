#!/usr/bin/env perl

use v5.10.0;
use warnings;
use Getopt::Long qw(GetOptions);

sub is_initialized {
	$MAEDIR=$ENV{'DIRMAE'};
	if ("$MAEDIR") {
		return 1;	
	} else {
		return 0;
	}
}

sub is_already_running {
	$counter = `ps -a | grep -c 'Listep'`;
	#$counterIfIsNotRunning = 2; #Linux
	$counterIfIsNotRunning = 3; #MAC
	if ($counter > $counterIfIsNotRunning) {
		return 1;
	} else {
		return 0;
	}
}

sub show_help {
	say "	Uso: $0 ARGS
	
	Argumento obligatorio!
	Listar un tipo de presupuesto: 'sanc', 'ejec', 'ctrl' 
	(Presupuesto sancionado, Presupuesto ejecutado o Presupuesto de control)
	
	Argumentos para presupuesto sancionado:
	ct : Ordenados por codigo de central y sino por trimestres
	tc : Ordenados por trimestres y sino por codigo de central
	
	Ejemplo: ./Listep.pl -sanc -ct 

	Argumentos para presupuesto ejecutado:
	all : Filtra todas las actividades
	act : Filtra una o mas actividades (Se pasan dentro de comillas, separados con \",\")
	
	Ejemplo: ./Listep.pl -ejec -act \"Actividad uno\", \"Actividad dos\"

	Argumentos para control de un presupuesto ejecutado:
	trim-all : Todos los trimestres
	trim : Uno o mas trimestres (Se pasan dentro de comillas, separados con \",\")
	cent-all : Todos los centros
	cent : Uno o mas centros (Se pasan dentro de comillas, separados con \",\")

	Ejemplo: ./Listep.pl -ctrl -trim \"Trimestre uno\", \"Trimestre dos\" -cent-all

	Para mostrar ayuda (esto): ./Listep.pl -h"
}

# Main!

unless (is_initialized) {
	say "No esta realizada la inicializacion de ambiente";
	exit 1;
}

if (is_already_running) {
	say "Ya hay un AFLIST corriendo";
	exit 1;
}

my $SANC;
my $EJEC;
my $CTRL;

my $SANC_CT;
my $SANC_TC;

my $EJEC_ALL;
my @EJEC_ACT=();

my $CTRL_TRIM_ALL;
my @CTRL_TRIM=();
my $CTRL_CENT_ALL;
my @CTRL_CENT=();

my $HELP=0;

GetOptions(
    'ct' => \$SANC_CT,
    'tc' => \$SANC_TC,
    'sanc' => \$SANC,
    'ejec' => \$EJEC,
    'ctrl' => \$CTRL,
    'all' => \$EJEC_ALL,
    'act=s{,}' => \@EJEC_ACT,
    'trim-all' => \$CTRL_TRIM_ALL,
    'trim=s{,}' => \@CTRL_TRIM,
    'cent-all' => \$CTRL_CENT_ALL,
    'cent=s{,}' => \@CTRL_CENT,
    'help|h' => \$HELP,
) or $HELP=1;

if ("$HELP") {
	show_help;
	exit 1;
}

unless ($SANC or $EJEC or $CTRL) {
	show_help;
	exit 1;
}

if ($SANC) {
	# Do something
}

if ($EJEC) {
	# Do something
}

if ($CTRL) {
	# Do something
}


