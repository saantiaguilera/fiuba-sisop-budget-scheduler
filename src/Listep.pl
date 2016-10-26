#!/usr/bin/env perl

######################################
############### LISTEP ###############
######################################
# If using OSX replace all grep -> ggrep / If using Linux distro replace ggrep -> grep

use v5.10.0; # Maybe we could use latest 5.18.2 But for compatibility measures lets leave it in 5.10
use warnings; # For lints and not being too error prone
use Getopt::Long qw(GetOptions); # GetOpt api
use Time::HiRes qw(time); # Time api

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

my $OUTPUT;
my $OUTPUT_FILE_NAME = time;
$OUTPUT_FILE_NAME =~ s/\.//g;
my $OUTPUT_FILE;

# UTILS

#######################################
# Checks if environment is initialized.
# Globals:
#   MAEDIR
# Returns:
#   True if initialized, false otherwise
#######################################
sub is_initialized {
	$MAEDIR=$ENV{'DIRMAE'};
	if ("$MAEDIR") {
		return 1;	
	} else {
		return 0;
	}
}

#######################################
# Show the help menu.
#######################################
sub show_help {
    say "Help can be found in the man. Run \"man ./Listep.man\" for more information :)";
}

# VERIFICATION

#######################################
# Verify sanction can be invoked safely.
# Globals:
#   EJEC / CTRL / SANC_CT / SANC_TC
# Returns:
#   true if there are problems, false if its ok
#######################################
sub verify_sanc() {
    # If using also ejec or ctrl, or both ct and tc are used (or none), git rekt.
    if ($EJEC or $CTRL or ($SANC_CT and $SANC_TC) or not($SANC_CT or $SANC_TC)) {
        show_help;
        return 1;
    }
    return 0;
}

#######################################
# Verify ejecutados can be invoked safely.
# Globals:
#   SANC / CTRL / EJEC_ALL / EJEC_ACT
# Returns:
#   true if there are problems, false if its ok
#######################################
sub verify_ejec() {
    # If using one of the others two, git rekt.
    if ($SANC or $CTRL or not($EJEC_ALL or @EJEC_ACT)) {
        show_help;
        return 1;
    }
    return 0;
}

#######################################
# Verify control can be invoked safely.
# Globals:
#   EJEC / SANC / CTRL_TRIM / CTRL_TRIM_ALL / CTRL_CENT / CTRL_CENT_ALL
# Returns:
#   true if there are problems, false if its ok
#######################################
sub verify_ctrl() {
    # If using one of the others two, git rekt.
    if ($SANC or $EJEC or not(@CTRL_TRIM or $CTRL_TRIM_ALL) or not(@CTRL_CENT or $CTRL_CENT_ALL)) {
        show_help;
        return 1;
    }
    return 0;
}

# Printings

#######################################
# Process sanction file and dump results.
# Globals:
#   OUTPUT_FILE / SANC_CT / SANC_TC
#######################################
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

	$OUTPUT_STRING = "Codigo Centro; Trimestre; Anio presupuestario;Total sancionado\n";
	print "$OUTPUT_STRING";
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}

	my $TOTAL_SUM = 0;
    my $SUBTOTAL_SUM = 0;
    my $LAST_INDEX = "";
	for (@ROWS) {
		my $COST_SUM = $_->[2] + $_->[3];
		
		my $NAME = "";
		if ($SANC_TC) {
			$NAME = $_->[0];
			#gggggggggggggggggggggggrep
			$NAME = `grep -r \Q$NAME\\\;\E \Q$MAEDIR/centros.csv`;
			chomp $NAME;
			$NAME =~ s/.+;//g;

            # If I sort by trimester first, subtotal is managed by trimester
            if ($LAST_INDEX eq "") {
                $LAST_INDEX = $_->[1];
            } else {
                unless ($LAST_INDEX eq $_->[1]) {
                    # The trimester changed, print
                    $LAST_INDEX = $_->[1];
	            	$OUTPUT_STRING = "Subtotal;$SUBTOTAL_SUM\n";
		            print "$OUTPUT_STRING";
	            	if (defined $OUTPUT) {
			            printf $OUTPUT_FILE "$OUTPUT_STRING";
	            	}
                    $SUBTOTAL_SUM = 0;
                }
            }
		}
		if ($SANC_CT) {
			$NAME = $_->[1];
			$NAME =~ s/1er/Primer/g;
			$NAME =~ s/2do/Segundo/g;
			$NAME =~ s/3er/Tercer/g;
			$NAME =~ s/4to/Cuarto/g;
	
            # If I sort by trimester first, subtotal is managed by trimester
            if ($LAST_INDEX eq "") {
                $LAST_INDEX = $_->[0];
            } else {
                unless ($LAST_INDEX eq $_->[0]) {
                    # The trimester changed, print
                    $LAST_INDEX = $_->[0];
	            	$OUTPUT_STRING = "Subtotal;$SUBTOTAL_SUM\n";
		            print "$OUTPUT_STRING";
	            	if (defined $OUTPUT) {
			            printf $OUTPUT_FILE "$OUTPUT_STRING";
	            	}
                    $SUBTOTAL_SUM = 0;
                }
            }
	}

		$OUTPUT_STRING = "$_->[0];$NAME;$COST_SUM\n";
		print "$OUTPUT_STRING";
		if (defined $OUTPUT) {
			printf $OUTPUT_FILE "$OUTPUT_STRING";
		}

		$TOTAL_SUM += $COST_SUM;
        $SUBTOTAL_SUM += $COST_SUM;
	}

	$OUTPUT_STRING = "Subtotal;$SUBTOTAL_SUM\nTotal Anual;$TOTAL_SUM\n";
	print "$OUTPUT_STRING";
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}
}

#######################################
# Contains method to filter entries by 
# acitivities passed as arguments.
# Globals:
#     EJEC_ALL / EJEC_ACT
# Returns:
#     true if exists, false otherwise.
#######################################
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

#######################################
# Process ejecutado file and dump results.
# Globals:
#   OUTPUT_FILE / EJEC_ALL / EJEC_ACT
#######################################
sub print_ejec() {
	# Headers of files we use:
	# row:      :id :date :central_code :act_name :trim :expense
	# act.csv:  :act_code :act_category :act_pgm :act_name
	# cent.csv: :central_code :central_name
	# axc.csv:  :act_code :central_code
    # id?? / date / central_code / acr_name / trim / expense ?


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

	$OUTPUT_STRING = "Fecha;Centro;Nom Cen;cod Act;Actividad;Trimestre;Gasto;control\n";
	print "$OUTPUT_STRING";
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}
	
	for (@ROWS) {
		my $ROW = $_;

		# ggggggggggggggggggrep
		my $FIELD_ACT_CODE = `grep -r \Q$ROW->[3]\E \Q$MAEDIR/actividades.csv`;
		my $FIELD_EXPENSE_SCHEDULED = "";
		if ($FIELD_ACT_CODE) {
			$FIELD_ACT_CODE =~ s/\;.+//g;
            $FIELD_ACT_CODE =~ s/.+\://g;

			my $EXISTS_IN_AXC = `grep -r \Q$FIELD_ACT_CODE\\\;$ROW->[2]\$\E \Q$MAEDIR/tabla-AxC.csv`;
			$FIELD_EXPENSE_SCHEDULED = $EXISTS_IN_AXC ? "" : "Gasto fuera de la planificacion.";
		} else {
			die "actividades.csv file doesn't contain $ROW->[3].";
		}

		# Get the central name.
		my $FIELD_CENTRAL_NAME = `grep -r \Q$ROW->[2]\\\;\E \Q$MAEDIR/centros.csv`;
		$FIELD_CENTRAL_NAME =~ s/.+\;//g;
        $FIELD_CENTRAL_NAME =~ s/\n//g;

		# No f'ing idea were to get the 'provincia'. Theres no field in any of the data sources. Only actividades.csv has :nom_act with some fields with 'provincias' but still there are a lot more without, so its not.

		$OUTPUT_STRING = "$ROW->[1];$ROW->[2];$FIELD_CENTRAL_NAME;$FIELD_ACT_CODE;$ROW->[3];$ROW->[4];$ROW->[5];$FIELD_EXPENSE_SCHEDULED\n";
		print "$OUTPUT_STRING";			
		if (defined $OUTPUT) {
			printf $OUTPUT_FILE "$OUTPUT_STRING";
		}
		
		$ROW->[5] =~ s/,/\./g;
		$FIELD_TOTAL_BUDGET += $ROW->[5];
	}

	$OUTPUT_STRING = ";;;;;Total Credito Fiscal; $FIELD_TOTAL_BUDGET;;\n";
	print "$OUTPUT_STRING";
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}
}

#######################################
# Contains method to filter entries by 
# trimester passed as arguments.
# Globals:
#     CTRL_TRIM_ALL / CTRL_TRIM
# Returns:
#     true if exists, false otherwise.
#######################################
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

#######################################
# Contains method to filter entries by 
# center passed as arguments.
# Globals:
#     CTRL_CENTER / CTRL_CENTER_ALL
# Returns:
#     true if exists, false otherwise.
#######################################
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

#######################################
# Append to stdout (and file) a new sanctioned entry, 
# updates trimester and sensible data.
# Globals:
#     TRIMESTRE_BUDGET / CUMULATIVE_BUDGET
#######################################
sub append_starting_budget_year() {
	my $LINE = `grep -r $LAST_LINE_CENTRAL\\\;\Q$LAST_LINE_TRIMESTRE\E \Q$CTRL[1]`;
	my @AUX = ( split ";", $LINE );
	$AUX[2] =~ s/,/\./g;
	$AUX[3] =~ s/,/\./g;

	$TRIMESTRE_BUDGET = ($AUX[2] + $AUX[3]);
	$CUMULATIVE_BUDGET += $TRIMESTRE_BUDGET;

	my $DATE = `grep -r \Q$LAST_LINE_TRIMESTRE\E \Q$MAEDIR/trimestres.csv`;
	@AUX = ( split ";", $DATE);
	$DATE = $AUX[2];
	$DATE =~ s/([0-9]{2})\/([0-9]{2})\/([0-9]{4})/$3$2$1/g;

	$OUTPUT_STRING = "(++);$DATE;$LAST_LINE_CENTRAL;0;$LAST_LINE_TRIMESTRE;$TRIMESTRE_BUDGET;$TRIMESTRE_BUDGET;;$CUMULATIVE_BUDGET\n";
	print "$OUTPUT_STRING";
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}
}

#######################################
# Check if should append to stdout (and file) a new sanctioned entry.
# This updates the last entry processed data.
# Globals:
#     LAST_LINE_CENTRAL / LAST_LINE_TRIMESTRE
# Returns:
#     true if should append, false otherwise.
#######################################
sub check_starting_budget_year {
	my ($CENTRAL_CODE, $TRIM) = @_;

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
		return 1;
	}
}

#######################################
# Process control file and dump results.
# Globals:
#   OUTPUT_FILE / CTRL_FILTERS
#######################################
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

	$OUTPUT_STRING = "Id;Fecha;Centro;Actividad;Trimestre;Importe;SALDO por TRIMESTRE;CONTROL;SALDO ACUMULADO\n";
	print "$OUTPUT_STRING";		
	if (defined $OUTPUT) {
		printf $OUTPUT_FILE "$OUTPUT_STRING";
	}

	for (@ROWS) {
		$ROW = $_;

		if (check_starting_budget_year($ROW->[2], $ROW->[4])) {
			append_starting_budget_year;
		}

		# ggggggggggggggggggrep
		$FIELD_ACT_CODE = `grep -r \Q$ROW->[3]\E \Q$MAEDIR/actividades.csv`;
		if ($FIELD_ACT_CODE) {
			$FIELD_ACT_CODE =~ s/\;.+//g;

			$EXISTS_IN_AXC = `grep -r \Q$FIELD_ACT_CODE\\\;$ROW->[2]\$\E \Q$MAEDIR/tabla-AxC.csv`;
			$FIELD_EXPENSE_SCHEDULED = $EXISTS_IN_AXC ? "" : "Gasto fuera de la planificacion.";
		} else {
			die "actividades.csv file doesn't contain $ROW->[3].";
		}

		$ROW->[5] =~ s/,/\./g;

		# Update trimestre budget.
		$TRIMESTRE_BUDGET -= $ROW->[5];

		# Check if trimestre budget is below zero, have message in control
		if ($TRIMESTRE_BUDGET < 0) {
			if ($FIELD_EXPENSE_SCHEDULED) {
				$FIELD_EXPENSE_SCHEDULED .= " ";
			}

			$FIELD_EXPENSE_SCHEDULED .= "Presupuesto excedido.";
		}

		# Update cumulative budget
		$CUMULATIVE_BUDGET -= $ROW->[5];

		$OUTPUT_STRING = "$ROW->[0];$ROW->[1];$ROW->[2];$ROW->[3];$ROW->[4];$ROW->[5];$TRIMESTRE_BUDGET;$FIELD_EXPENSE_SCHEDULED;$CUMULATIVE_BUDGET\n";
		print "$OUTPUT_STRING";	
		if (defined $OUTPUT) {
			printf $OUTPUT_FILE "$OUTPUT_STRING";
		}
	}
}

# Main!

unless (is_initialized) {
	say "No esta inicializado el environment";
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
    'help|h' => \$HELP,
    'output|o:s' => \$OUTPUT
) or $HELP = 1;

if ($HELP) {
	show_help;
	exit 0;
}

if (defined $OUTPUT) {
	if (length $OUTPUT > 0) {
		$OUTPUT_FILE_NAME .= ("-" . $OUTPUT);
	} else {
		$OUTPUT_FILE_NAME = (time . "-listep-file.csv");
	}
}

unless ($SANC or $EJEC or @CTRL) {
	show_help;
	exit 1;
}

if ($SANC) {
	unless (verify_sanc) {
		# Lazy to do this modularized.. Will be copypasta 3 times
		if (defined $OUTPUT) {
			open($OUTPUT_FILE, '>', $OUTPUT_FILE_NAME) or die "Could not open file '$OUTPUT_FILE_NAME' $!";
		}
		print_sanc;
		if (defined $OUTPUT) {
			close $OUTPUT_FILE;
		}
	}
	exit 0;
}

if ($EJEC) {
	unless (verify_ejec) {
		# Lazy to do this modularized.. Will be copypasta 3 times
		if (defined $OUTPUT) {
			open($OUTPUT_FILE, '>', $OUTPUT_FILE_NAME) or die "Could not open file '$OUTPUT_FILE_NAME' $!";
		}
		print_ejec;
		if (defined $OUTPUT) {
			close $OUTPUT_FILE;
		}
	}
	exit 0;
}

if (@CTRL) {
	unless (verify_ctrl) {
		# Lazy to do this modularized.. Will be copypasta 3 times
		if (defined $OUTPUT) {
			open($OUTPUT_FILE, '>', $OUTPUT_FILE_NAME) or die "Could not open file '$OUTPUT_FILE_NAME' $!";
		}
		print_ctrl;
		if (defined $OUTPUT) {
			close $OUTPUT_FILE;
		}
	}
	exit 0;
}
