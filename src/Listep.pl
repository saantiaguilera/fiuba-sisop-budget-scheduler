#!/usr/bin/env perl

# Add docs to functions

use v5.10.0;
use warnings;
use Getopt::Long qw(GetOptions);

# Args Variables

my $SANC;
my $EJEC;
my $CTRL;

my $SANC_CT;
my $SANC_TC;

my $EJEC_ALL;
my @EJEC_ACT = ();

my $CTRL_TRIM_ALL;
my @CTRL_TRIM = ();
my $CTRL_CENT_ALL;
my @CTRL_CENT = ();

my $HELP = 0;

# UTILS

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
	Listar un tipo de presupuesto: 'sanc', 'ejec', 'ctrl' seguido del archivo a procesar
	(Presupuesto sancionado, Presupuesto ejecutado o Presupuesto de control).
	Nota: Solo puede estar presente uno de los tres.

	Ejemplo: ./Listep.pl -sanc path/a/mi/archivo.csv
	
	Argumentos para presupuesto sancionado:

	ct : Ordenados por codigo de central y sino por trimestres
	tc : Ordenados por trimestres y sino por codigo de central
	Nota: Solo se puede ingresar uno de los dos.
	
	Ejemplo: ./Listep.pl -sanc -ct 

	Argumentos para presupuesto ejecutado:

	all : Filtra todas las actividades
	act : Filtra una o mas actividades (Se pasan dentro de comillas, separados con \",\")
	
	Ejemplo: ./Listep.pl -ejec -act \"Actividad uno\", \"Actividad dos\"
	Nota: Si no se pasan filtros, se tomara por default -all
	Nota: Si se pasan tanto filtros de act como de all, se invalidan los de act y se usan solo all. (Uno pisa al otro)

	Argumentos para control de un presupuesto ejecutado:
	
	trim-all : Todos los trimestres
	trim : Uno o mas trimestres (Se pasan dentro de comillas, separados con \",\")
	cent-all : Todos los centros
	cent : Uno o mas centros (Se pasan dentro de comillas, separados con \",\")

	Ejemplo: ./Listep.pl -ctrl -trim \"Trimestre uno\", \"Trimestre dos\" -cent-all
	Nota: Si no se pasan filtros, se tomaran por default trim-all y cent-all.
	Nota: Si se pasan filtros especificos y el -all en algun caso, se tomaran todos y no se hara uso de los especificos
    
	Para mostrar ayuda (esto): ./Listep.pl -h"
}

# VERIFICATION

sub verify_sanc() {
    # If using also ejec or ctrl, or both ct and tc are used (or none), git rekt.
    if ($EJEC or $CTRL or ($SANC_CT and $SANC_TC) or not($SANC_CT or $SANC_TC)) {
        show_help;
        return 1;
    }
    return 0;
}

sub verify_ejec() {
    # If using one of the others two, git rekt.
    if ($SANC or $CTRL) {
        show_help;
        return 1;
    }
    return 0;
}

sub verify_ctrl() {
    # If using one of the others two, git rekt.
    if ($SANC or $EJEC) {
        show_help;
        return 1;
    }
    return 0;
}

# Printings

sub print_sanc() {
	# Filename should come dynamically in the getopt of snac/ejec/ctrl
	open(DATA, "<", "$SANC") or die "Couldn't open file $SANC, reason: $!";

	# Parse csv splitting by ;. Avoid the header.
	<DATA>; # Read the header
	my @rows = map { chomp; [ split ";", $_ ] } <DATA>;

	# Modify some stuff about each row (because its really hard to operate how its by default)
	for (@rows) {
		$_->[1] =~ s/Primer/1er/g;
		$_->[1] =~ s/Segundo/2do/g;
		$_->[1] =~ s/Tercer/3er/g;
		$_->[1] =~ s/Cuarto/4to/g;
		$_->[2] =~ s/,/\./g;
		$_->[3] =~ s/,/\./g;
	}
	
	@rows = sort { $a->[$SANC_CT ? 0 : 1] cmp $b->[$SANC_CT ? 0 : 1] or
					$a->[$SANC_CT ? 1 : 0] cmp $b->[$SANC_CT ? 1 : 0] } @rows;
	
	close DATA or warn $! ? "Error closing sort pipe: $!"
                   : "Exit status $? from sort";

	say "A;o presupuestario, Total sancionado";
	$TOTAL_SUM = 0;
	for (@rows) {
		$COST_SUM = $_->[2] + $_->[3];
		
		if ($SANC_TC) {
			$NAME = $_->[0];
			$NAME = `ggrep -r $NAME\\\; $MAEDIR/centros.csv`;
			chomp $NAME;
			$NAME =~ s/.+;//g;
		}
		if ($SANC_CT) {
			$NAME = $_->[1];
			$NAME =~ s/1er/Primer/g;
			$NAME =~ s/2do/Segundo/g;
			$NAME =~ s/3er/Tercer/g;
			$NAME =~ s/4to/Cuarto/g;
		}

		say "$NAME, $COST_SUM";
		$TOTAL_SUM += $COST_SUM;
	}
	say "Total Anual: $TOTAL_SUM";
}

sub print_ejec() {

}

# Main!

unless (is_initialized) {
	say "No esta realizada la inicializacion de ambiente";
	exit 1;
}

if (is_already_running) {
	say "Ya hay un Listep corriendo";
	exit 1;
}

GetOptions(
    'sanc=s' => \$SANC,
    'ejec=s' => \$EJEC,
    'ctrl=s' => \$CTRL,
    'ct' => \$SANC_CT,
    'tc' => \$SANC_TC,
    'all' => \$EJEC_ALL,
    'act=s{,}' => \@EJEC_ACT,
    'trim-all' => \$CTRL_TRIM_ALL,
    'trim=s{,}' => \@CTRL_TRIM,
    'cent-all' => \$CTRL_CENT_ALL,
    'cent=s{,}' => \@CTRL_CENT,
    'help|h' => \$HELP
) or $HELP = 1;

if ("$HELP") {
	show_help;
	exit 1;
}

unless ($SANC or $EJEC or $CTRL) {
	show_help;
	exit 1;
}

if ($SANC) {
	unless (verify_sanc) {
		print_sanc;
    }
	exit 0;
}

if ($EJEC) {
    unless (verify_ejec) {
    	# Do something
    }
	exit 0;
}

if ($CTRL) {
	if (not(verify_ctrl)) {
        print_ejec;
    }
    exit 0;
}
