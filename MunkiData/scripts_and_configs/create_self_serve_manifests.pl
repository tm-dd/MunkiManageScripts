#!/usr/bin/perl
#
# read a CSV file and create different SelfServeManifest files, based on the rules of the CSV file
# 
# Copyright (C) 2023 tm-dd (Thomas Mueller)
# 
# Redistribution and use in SOURCE and BINARY forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# settings
#

# set the level of debugging
$DEBUG=0;

# the csv file with all software to read
my $csvFileToRead='/usr/local/MunkiData/scripts_and_configs/munki_self_serve_manifests.csv ';

# the folder for the new SelfServeManifests, to create later
my $selfServeManifestsFolder="/usr/local/MunkiData/scripts_and_configs/self_serve_manifests";

# the temporaery bash script to update create the SelfServeManifests
my $shellScriptToRun='/tmp/update_munki_SelfServeManifests.sh';

# 2d array of any lines and fields
my @csvArrayOfAllFields;

# list of SelfManifestNames
my @listOfSelfServeManifests;

#
# functions
#

# print a 1D array
sub print1dArray
{
    $fieldDelimiters = shift;
    $referenceOfArray = shift;
    foreach $line (@{$referenceOfArray})
    {
            print $line.$fieldDelimiters;
    }
    print "\n";
}

# print a 2D array
sub print2dArray
{
	$fieldDelimiters = shift;
	$referenceOfArray = shift;
	$printEmptyLines = shift;  # 0 == no ; 1 == yes
	
	foreach $line (@{$referenceOfArray})
	{
		my $lineNotEmpty=$printEmptyLines;
		foreach $element (@$line)
		{
			if ( $element ne '' ) { print $element.$fieldDelimiters; $lineNotEmpty=1; }
		}
		if ( $lineNotEmpty == 1 ) { print "\n"; }
	}
}

# read CSV file and put all valid lines to @csvArrayOfAllFields
sub readCsvFileToArray
{
	$fileName = shift;
	
	my $line; my $firstChar; my @csvArray; my $lineNumber=0;
	
	open (fileHandler,'<'.$fileName) or die("Error: Could not read file '$fileName'. $!");
	while (<fileHandler>)
	{
		chomp($line=$_);
		
		if ($DEBUG>=3) { print '  DEBUG: readed   CSV file: '.$line."\n"; }
		
		# replace ',"b",,"d"' to '" ","b"," ","d"' for a "clear" CSV syntax
		$line =~ s/^,/" ",/g;
		$line =~ s/,$/," "/g;
		$line =~ s/,,/," ",/g;
		$line =~ s/,,/," ",/g;
		if ($DEBUG>=3) { print '  DEBUG: replaced CSV file: '.$line."\n"; }
		
		# remove first and last '"' in any line
		$line=substr($line,1);
		$line=substr($line,0,-1);
		my @csvLine = split '","' , $line;
		
		# ignore comment lines and all lines with an empty first field
		$firstChar=substr($line,0,1);
		if ( ( $firstChar ne '#' ) && ( $firstChar ne ' ' ) )
		{
			if ($DEBUG>=2) { print '  DEBUG: import   CSV file: '.$line."\n"; }
			$csvArrayOfAllFields[$lineNumber]=\@csvLine;
			$lineNumber++;
		}
		else
		{
			if ($DEBUG>=3) { print '  DEBUG: IGNORE   CSV file: '.$line."\n"; }
		}
	}
	close fileHandler;
}

# build the array @listOfSelfServeManifests with all names of needed SelfServeManifests
sub findSelfServeManifests
{
	my $referenceOfArray=shift;

	foreach $line (@{$referenceOfArray})
	{
		my $foundSelfServeManifest = @$line[0];
		my $foundInArray=0;

		foreach $nameOfServeManifests (@listOfSelfServeManifests)
		{
			if ("$foundSelfServeManifest" eq "$nameOfServeManifests") { $foundInArray=1; } else { $foundInArray=0; }
		}
		if ($foundInArray==0)
		{
			if ($DEBUG>=2) { print "found NEW SelfServeManifest: $foundSelfServeManifest\n"; }
			push (@listOfSelfServeManifests,$foundSelfServeManifest);
		}
	}
}

# recursiv function to update includes SelfServeManifests in a SelfServeManifest
sub updateSelfServeManifests
{
	my $nameOfSelfServeManifestsToUpdate=shift;
	my $nameOfSelfServeManifestsToInclude=shift;
	my $referenceOfCsvArrayOfAllFields=shift;

	foreach $line (@{$referenceOfCsvArrayOfAllFields})
	{
		my $nameOfSelfServeManifests = @$line[0];
		my $includeSelfServeManifests = @$line[1];
		
		# add managed_installs and managed_uninstalls and start a new recursiv loop over all SelfServeManifests to include
		if ( "$nameOfSelfServeManifests" eq "$nameOfSelfServeManifestsToInclude" )
		{
			my $managedInstalls = @$line[2];
			my $managedUninstalls = @$line[3];

			if ( "$managedInstalls" ne " " ) { print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfSelfServeManifestsToUpdate managed_installs -array-add ".'"'."$managedInstalls".'"'."\n"; }
			if ( "$managedUninstalls" ne " " ) { print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfSelfServeManifestsToUpdate managed_uninstalls -array-add ".'"'."$managedUninstalls".'"'."\n"; }
			if ( "$includeSelfServeManifests" ne " " ) { updateSelfServeManifests($nameOfSelfServeManifestsToUpdate,$includeSelfServeManifests,$referenceOfCsvArrayOfAllFields); }
		}
	}
}

# create and write the SelfServeManifests
sub writeSelfServeManifests
{
	my $referenceOflistOfSelfServeManifests=shift;
	my $referenceOfCsvArrayOfAllFields=shift;

	# write empty DICT for managed_installs and managed_uninstalls
	foreach $nameOfServeManifests (@{$referenceOflistOfSelfServeManifests})
	{	
		print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfServeManifests managed_installs -array-add\n";	
		print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfServeManifests managed_uninstalls -array-add\n";
	}

	# add managed_installs and managed_uninstalls and start a recursiv loop over all SelfServeManifests to include
	foreach $line (@{$referenceOfCsvArrayOfAllFields})
	{
		my $nameOfSelfServeManifests = @$line[0];
		my $includeSelfServeManifests = @$line[1];
		my $managedInstalls = @$line[2];
		my $managedUninstalls = @$line[3];

		if ( "$managedInstalls" ne " " ) { print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfSelfServeManifests managed_installs -array-add ".'"'."$managedInstalls".'"'."\n"; }
		if ( "$managedUninstalls" ne " " ) { print SHELLSCRIPT "defaults write $selfServeManifestsFolder/$nameOfSelfServeManifests managed_uninstalls -array-add ".'"'."$managedUninstalls".'"'."\n"; }
		if ( "$includeSelfServeManifests" ne " " ) { updateSelfServeManifests($nameOfSelfServeManifests,$includeSelfServeManifests,$referenceOfCsvArrayOfAllFields); }
	}

	# change to the XML format
	foreach $nameOfServeManifests (@{$referenceOflistOfSelfServeManifests})
	{
		print SHELLSCRIPT "plutil -convert xml1 $selfServeManifestsFolder/$nameOfServeManifests.plist \n";
		print SHELLSCRIPT "mv $selfServeManifestsFolder/$nameOfServeManifests.plist $selfServeManifestsFolder/$nameOfServeManifests \n";
	}
}

#
# main loop
#

# create a bash script for the commands to create the SelfServeManifests
open (SHELLSCRIPT,">$shellScriptToRun");

# read CSV file
readCsvFileToArray($csvFileToRead);

# show the importand lines of the CSV file
if ($DEBUG>=1) 
{
	print "csvArrayOfAllFields:\n"; 
	print2dArray(' | ',\@csvArrayOfAllFields,0);
}

# create a list of all needed SelfServeManifests
findSelfServeManifests(\@csvArrayOfAllFields);

# show the list of all needed SelfServeManifests
if ($DEBUG>=1) { print1dArray(' ',\@listOfSelfServeManifests); }

# create new directory for the files of SelfServeManifests
print SHELLSCRIPT "rm -rf $selfServeManifestsFolder \n";
print SHELLSCRIPT "mkdir $selfServeManifestsFolder \n"; 

# write new SelfServeManifests
writeSelfServeManifests(\@listOfSelfServeManifests,\@csvArrayOfAllFields);

# show the new SelfServeManifests
print SHELLSCRIPT "set -x; ls -l $selfServeManifestsFolder \n";

close (SHELLSCRIPT);

# whow and run the bash script
system ("clear; cat $shellScriptToRun");
print "\nPRESS ENTER to create the new SelfServeManifests with the upper commands.";
system ("read && echo && zsh $shellScriptToRun");

exit 0;
