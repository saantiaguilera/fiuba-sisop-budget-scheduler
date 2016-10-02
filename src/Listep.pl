#!/usr/bin/env perl

# Add docs to functions

use v5.10.0;
use warnings;
use Getopt::Long qw(GetOptions);

# Args Variables

my $SANC;
my $EJEC;
my @CTRL = ();

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
	$COUNTER = `ps -a | grep -c 'Listep'`;
	#$COUNTER_IF_ISNT_RUNNING = 2; #Linux
	$COUNTER_IF_ISNT_RUNNING = 3; #MAC
	if ($COUNTER > $COUNTER_IF_ISNT_RUNNING) {
		return 1;
	} else {
		return 0;
	}
}

sub show_help {
	say "Uso: $0 -[sanc|ejec|ctrl] -[ct|tc] -[act|all] -[trim|trim-all|cent|cent-all]
	
Arguments:

--sanc: Lista en modo de sanciones. Debe estar seguido de un archivo de sanciones a ser procesado.

--ejec: Lista en modo de ejecutados. Debe estar seguido de un archivo de presupuestos a ser procesado.

--ctrl: Lista en modo de control. Debe estar seguido de un archivo de presupuestos y otro de sanciones.

	Nota: Solo uno de los tres puede estar presente a la vez.

	Ejemplo: ./Listep.pl -sanc path/a/mi/archivo.csv
	
Arguments para presupuesto sancionado:

-ct : Ordenados por codigo de central y sino por trimestres
	
-tc : Ordenados por trimestres y sino por codigo de central
	
	Nota: Solo se puede ingresar uno de los dos.
	
	Ejemplo: ./Listep.pl -sanc -ct 

Arguments para presupuesto ejecutado:

-all : Filtra todas las actividades
	
-act : Filtra una o mas actividades (Se pasan dentro de comillas, separados con espacios)
	
	Nota: Si se pasan tanto filtros de act como de all, se invalidan los de act y se usan solo all. (Uno pisa al otro)

	Ejemplo: ./Listep.pl -ejec -act \"Actividad uno\" \"Actividad dos\"

Arguments para control de un presupuesto ejecutado:
	
-trim-all : Todos los trimestres
	
-trim : Uno o mas trimestres (Se pasan dentro de comillas, separados cone spacios)
	
-cent-all : Todos los centros
	
-cent : Uno o mas centros (Se pasan dentro de comillas, separados con espacios)

	Nota: Si se pasan filtros especificos y el -all en algun caso, se tomaran todos y no se hara uso de los especificos
    
	Ejemplo: ./Listep.pl -ctrl -trim \"Trimestre uno\" \"Trimestre dos\" -cent-all

-h : Help"
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
    if ($SANC or $CTRL or not($EJEC_ALL or @EJEC_ACT)) {
        show_help;
        return 1;
    }
    return 0;
}

sub verify_ctrl() {
    # If using one of the others two, git rekt.
    if ($SANC or $EJEC or not(@CTRL_TRIM or $CTRL_TRIM_ALL) or not(@CTRL_CENT or $CTRL_CENT_ALL)) {
        show_help;
        return 1;
    }
    return 0;
}

# Printings

sub print_sanc() {	
	# Headers of files we use:
	# row:      :centre_code :trim :expense1 :expense2
	# cent.csv: :centre_code :centre_name

	open(DATA, "<", "$SANC") or die "Couldn't open file $SANC, reason: $!";

	# Parse csv splitting by ;. Avoid the header.
	<DATA>; # Read the header
	my @ROWS = map { chomp; [ split ";", $_ ] } <DATA>;

	# Modify some stuff about each row (because its really hard to operate how its by default)
	for (@ROWS) {
		$_->[1] =~ s/Primer/1er/g;
		$_->[1] =~ s/Segundo/2do/g;
		$_->[1] =~ s/Tercer/3er/g;
		$_->[1] =~ s/Cuarto/4to/g;
		$_->[2] =~ s/,/\./g;
		$_->[3] =~ s/,/\./g;
	}
	
	@ROWS = sort { $a->[$SANC_CT ? 0 : 1] cmp $b->[$SANC_CT ? 0 : 1] or
					$a->[$SANC_CT ? 1 : 0] cmp $b->[$SANC_CT ? 1 : 0] } @ROWS;
	
	close DATA or warn $! ? "Error closing sort pipe: $!"
                   : "Exit status $? from sort";

	say "Anio presupuestario;Total sancionado";
	my $TOTAL_SUM = 0;
	for (@ROWS) {
		my $COST_SUM = $_->[2] + $_->[3];
		
		my $NAME = "";
		if ($SANC_TC) {
			$NAME = $_->[0];
			#ggggggggggggggggggggggggrep
			$NAME = `ggrep -r \Q$NAME\\\;\E \Q$MAEDIR/centros.csv`;
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

		say "$NAME;$COST_SUM";
		$TOTAL_SUM += $COST_SUM;
	}
	say "Total Anual;$TOTAL_SUM";
}

sub contains_activity {
	my ($LINE) = @_;

	if ($EJEC_ALL) {
		return 1; # TRUE
	} else {
		for (@EJEC_ACT) {
			if ($LINE =~ m/$_/i) {
				return 1;
			}
		}

		return 0;
	}
}

sub print_ejec() {
	# Headers of files we use:
	# row:      :id :date :central_code :act_name :trim :expense
	# act.csv:  :act_code :act_category :act_pgm :act_name
	# cent.csv: :central_code :central_name
	# axc.csv:  :act_code :central_code

	open(DATA, "<", "$EJEC") or die "Couldn't open file $EJEC, reason: $!";

	# Parse csv splitting by ;. Avoid the header.
	<DATA>; # Read the header
	my @ROWS = map { 
		chomp; 
		contains_activity($_) ? [ split ";", $_ ] : ();
	} <DATA>;

	close DATA or warn $! ? "Error closing sort pipe: $!"
                   : "Exit status $? from sort";

	@ROWS = sort { $a->[3] cmp $b->[3] } @ROWS;

	my $FIELD_TOTAL_BUDGET = 0;
	say "Fecha;Centro;Nom Cen;cod Act; Actividad; Trimestre; Gasto; control";
	for (@ROWS) {
		my $ROW = $_;

		# gggggggggggggggggggrep
		my $FIELD_ACT_CODE = `ggrep -r \Q$ROW->[3]\E \Q$MAEDIR/actividades.csv`;
		my $FIELD_EXPENSE_SCHEDULED = "";
		if ($FIELD_ACT_CODE) {
			$FIELD_ACT_CODE =~ s/\;.+//g;

			my $EXISTS_IN_AXC = `ggrep -r \Q$FIELD_ACT_CODE\\\;$ROW->[2]\$\E \Q$MAEDIR/tabla-AxC.csv`;
			$FIELD_EXPENSE_SCHEDULED = $EXISTS_IN_AXC ? "" : "gasto fuera de la planificacion";
		} else {
			die "actividades.csv file doesn't contain $ROW->[3].";
		}

		# Get the central name.
		my $FIELD_CENTRAL_NAME = `ggrep -r \Q$ROW->[2]\\\;\E \Q$MAEDIR/centros.csv`;
		$FIELD_CENTRAL_NAME =~ s/.+\;//g;

		# No f'ing idea were to get the 'provincia'. Theres no field in any of the data sources. Only actividades.csv has :nom_act with some fields with 'provincias' but still there are a lot more without, so its not.

		say "$ROW->[1];$ROW->[2];$FIELD_CENTRAL_NAME;$FIELD_ACT_CODE;$ROW->[3];$ROW->[4];$ROW->[5];$FIELD_EXPENSE_SCHEDULED";
		
		$ROW->[5] =~ s/,/\./g;
		$FIELD_TOTAL_BUDGET += $ROW->[5];
	}
	say ";;;;;Total Credito Fiscal; $FIELD_TOTAL_BUDGET;;"
}

sub contains_trimester {
	my ($LINE) = @_;

	if ($CTRL_TRIM_ALL) {
		return 1; # TRUE
	} else {
		for (@CTRL_TRIM) {
			if ($LINE =~ m/$_/i) {
				return 1;
			}
		}

		return 0;
	}
}

sub contains_center {
	my ($LINE) = @_;

	if ($CTRL_CENT_ALL) {
		return 1; # TRUE
	} else {
		for (@CTRL_CENT) {
			if ($LINE =~ m/$_/i) {
				return 1;
			}
		}

		return 0;
	}
}

sub append_starting_budget_year() {
	my $LINE = `ggrep -r $LAST_LINE_CENTRAL\\\;\Q$LAST_LINE_TRIMESTRE\E $CTRL[1]`;
	my @AUX = ( split ";", $LINE );
	$AUX[2] =~ s/,/\./g;
	$AUX[3] =~ s/,/\./g;
	$TRIMESTRE_BUDGET = ($AUX[2] + $AUX[3]);
	$CUMULATIVE_BUDGET += $TRIMESTRE_BUDGET;

	my $DATE = `ggrep -r $LAST_LINE_TRIMESTRE $MAEDIR/trimestres.csv`;
	@AUX = ( split ";", $DATE);
	$DATE = $AUX[2];

	say "(++);$DATE;$LAST_LINE_CENTRAL;0;$LAST_LINE_TRIMESTRE;$TRIMESTRE_BUDGET;$TRIMESTRE_BUDGET;;$CUMULATIVE_BUDGET";
}

sub check_starting_budget_year {
	my ($ID, $DATE, $CENTRAL_CODE, $ACT_NAME, $TRIM, $EXPENSE) = @_;

	if ($LAST_LINE_CENTRAL and $LAST_LINE_TRIMESTRE) {
		#LOGIC FOR CHECKING IF ITS A NEW TRIMESTRE OR CODE AND PRINTING
		unless ($CENTRAL_CODE =~ $LAST_LINE_CENTRAL and $TRIM =~ $LAST_LINE_TRIMESTRE) {
			$LAST_LINE_CENTRAL = $CENTRAL_CODE;
			$LAST_LINE_TRIMESTRE = $TRIM;
			return 1;
		}

		return 0;
	} else {
		# Theres no last line, create it and append stuff
		$LAST_LINE_CENTRAL = $CENTRAL_CODE;
		$LAST_LINE_TRIMESTRE = $TRIM;

		say "$LAST_LINE_TRIMESTRE, $LAST_LINE_CENTRAL";
		return 1;
	}
}

sub print_ctrl() {
	# Headers of files we use:
	# row:      :id :date :central_code :act_name :trim :expense
	# act.csv:  :act_code :act_category :act_pgm :act_name
	# cent.csv: :central_code :central_name
	# axc.csv:  :act_code :central_code

	open(DATA, "<", "$CTRL[0]") or die "Couldn't open file $CTRL[0], reason: $!";

	# Parse csv splitting by ;. Avoid the header.
	<DATA>; # Read the header
	my @ROWS = map { 
		chomp; 
		(contains_trimester($_) and contains_center($_)) ? [ split ";", $_ ] : ();
	} <DATA>;
	
	close DATA or warn $! ? "Error closing sort pipe: $!"
                   : "Exit status $? from sort";

	# Sort by trimester -> central_code -> date.
	@ROWS = sort { $a->[4] cmp $b->[4] or
					$a->[2] cmp $b->[2] or
					$a->[1] cmp $b->[1] } @ROWS;

	$CUMULATIVE_BUDGET = 0;
	$TRIMESTRE_BUDGET = 0;
	$LAST_LINE_CENTRAL = "";
	$LAST_LINE_TRIMESTRE = "";
	say "Id;Fecha;Centro;Actividad;Trimestre;Importe;SALDO por TRIMESTRE;CONTROL; SALDO ACUMULADO";
	for (@ROWS) {
		$ROW = $_;

		if (check_starting_budget_year($ROW)) {
			append_starting_budget_year;
		}

		return 1;

		# gggggggggggggggggggrep
		$FIELD_ACT_CODE = `ggrep -r \Q$ROW->[3]\E \Q$MAEDIR/actividades.csv`;
		if ($FIELD_ACT_CODE) {
			$FIELD_ACT_CODE =~ s/\;.+//g;

			$EXISTS_IN_AXC = `ggrep -r \Q$FIELD_ACT_CODE\\\;$ROW->[2]\$\E \Q$MAEDIR/tabla-AxC.csv`;
			$FIELD_EXPENSE_SCHEDULED = $EXISTS_IN_AXC ? "" : "gasto fuera de la planificacion";
		} else {
			die "actividades.csv file doesn't contain $ROW->[3].";
		}

		$ROW->[5] =~ s/,/\./g;

		# Update trimestre budget.
		$TRIMESTRE_BUDGET -= $ROW->[5];

		# Check if trimestre budget is below zero, have message in control
		if ($TRIMESTRE_BUDGET < 0) {
			$FIELD_EXPENSE_SCHEDULED += ". Presupuesto excedido.";
		}

		# Update cumulative budget
		$CUMULATIVE_BUDGET -= $ROW->[5];

		say "$ROW->[0];$ROW->[1];$ROW->[2];$ROW->[3];$ROW->[4];$ROW->[5];$TRIMESTRE_BUDGET;$FIELD_EXPENSE_SCHEDULED;$CUMULATIVE_BUDGET";
	}
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
    'ctrl=s{2,2}' => \@CTRL,
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

unless ($SANC or $EJEC or @CTRL) {
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
    	print_ejec;
    }
	exit 0;
}

if (@CTRL) {
	unless (verify_ctrl) {
        print_ctrl;
    }
    exit 0;
}
