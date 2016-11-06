package Cobertura;

use strict;
use base qw(Step);
use IO::All;
#use XML::LibXML;
#use XML::LibXSLT;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
#	my $tcdir = $self->genPath($self->builder()->getProperty("test.$step.testclasses"));
	my $cdir = $self->builder()->getScalarProperty("test.$step.sourceclasses");
	my $cbloc = $self->builder()->getScalarProperty("cobertura.coberturabin");
	my $cbout = $self->builder()->getScalarProperty("test.$step.classes");
	my $cbdata = $self->builder()->getScalarProperty("test.$step.cbdatafile");
	io($cbout)->mkpath();
	io($cbdata)->unlink() if -f $cbdata;

# more test class monkey horsepoop. It seems Cobertura also doesn't feel like copying ALL the classes
# as they should. What exactly is it about java tool developers which makes them stupid????!!!!!!!
	$self->_copyTree($cdir,$cbout,".*\.class");

	$self->debug("$cbloc/bin/cobertura-instrument.sh --datafile $cbdata --destination $cbout $cdir");
	$self->error("Cobertura failed to instrument classes") if
		system("$cbloc/cobertura-instrument.sh",'--datafile',$cbdata,'--destination',$cbout,$cdir);
	$self->registerCleanupStep('cobreport');
	$self->info("Classes instrumented");
}

sub report {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $cbloc = $self->builder()->getScalarProperty("cobertura.coberturabin");
	my $repdir = $self->builder()->getScalarProperty("test.$step.reports");
	my $cbdata = $self->builder()->getScalarProperty("test.$step.cbdatafile");
	my $source = $self->builder()->getScalarProperty("build.source");
	io($repdir)->mkpath();

	$self->debug("$cbloc/cobertura-report.sh --datafile $cbdata --destination $repdir");
	$self->error("Cobertura failed to generate report") if
		system("$cbloc/cobertura-report.sh",'--datafile',$cbdata,'--destination',$repdir,$source);
	$self->info("Report generated");
}

sub merge {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $cbloc = $self->getScalarProperty("cobertura.coberturabin");
	my $cbdata = $self->getScalarProperty("test.$step.cbdatafile");
	my $sourcedata = $self->builder()->mergePropertyValues("test.$step.mergefiles"," ");

	$self->debug("merging $sourcedata into $cbdata");
	$self->error("Cobertura failed to merge data") if
		system("$cbloc/cobertura-merge.sh",'--datafile',$cbdata,$sourcedata);
	$self->info("Data merged");
}

1;


__END__

=head1 NAME

Cobertura - Dilettante Cobertura instrumentation and report generation module

=head1 DESCRIPTION

NOTE: Cobertura appears to be effectively a dead project at this point. This module will no longer be maintained. For an
alternative check out the Jacoco module.

This module provides a default action which instruments java .class files for test coverage reporting by Cobertura, and
a report action which generates an html test coverage report from information generated by the instrumented classes during
test runs.

=head2 INSTRUMENTATION CONFIGURATION

Several properties control the instrumentation 

=over 4

=item test.$step.sourceclasses

This is the path to the compiled files being tested. These will be instrumented for test coverage.

=item test.$step.classes

Output directory for instrumented class files.

=item test.$step.cbdatafile

Name of the cobertura data file to merge into.

=item test.$step.mergefiles

Name of cobertura data files to merge into the cbdatafile.

=back

=head2 REPORT CONFIGURATION

test.$step.reports is the directory where the generated reports will be placed.

=head1 USE

In order to actually gather information the tests need to be run via the 'cobtest' step which is configured in the
default global config.properties to use a classpath containing the instrumented build files. The only other requirement
is establishing a test scope dependency on the cobertura runtime jar library.


=head1 AUTHOR

Tod G. Harter

=head1 LICENSE

This software is Copyright (C) 2016 TD Software Inc. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
