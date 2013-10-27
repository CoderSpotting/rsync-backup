# Copyright 2013 - Bavo De Ridder <http://www.bavoderidder.com/>
#
# This file is part of rsync-backup.
#
# Rsync-backup is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Rsync-backup is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with mysql-backup.  If not, see <http://www.gnu.org/licenses/>.

use Data::Dumper;

$debug = 0;

sub processHost
{
	my (%hostConfig) = @_;

	my $hostname = $hostConfig{'hostname'};
	my $sshKey = $hostConfig{'sshKey'};
	my $config = $hostConfig{'folders'};


	foreach $folderPair (@$config)
	{
		my $remoteFolder = $folderPair->{'remoteFolder'};

		if ($remoteFolder !~ m(/$))
		{
			$remoteFolder = $remoteFolder . '/';
		}

		my $localFolder = constructLocalFolder($hostname, $folderPair->{'localFolder'});

		syncStaging($hostname, $sshKey, $remoteFolder, $localFolder);
	}
	
	my $lastBackupDate = getLastBackupDate(constructBackupBase($hostname));

	my $newBackupDate = getDatePostfix();

	rotateBackup(constructBackupBase($hostname), $lastBackupDate, $newBackupDate);

	#calculateBackupSize($hostname, constructBackupBase($hostname), "backup.$newBackupDate");
}

sub constructBackupBase
{
	my ($hostname) = @_;
	
	return $mainConfig{'basepath'} . "/storage/" . $hostname . "/rsync";
}

sub constructLocalFolder
{
	my ($hostname, $localFolder) = @_;
	
	return constructBackupBase($hostname) . "/staging/" . $localFolder . "/";
}

sub getDatePostfix
{
	my $date = `date +%Y%m%0d%H%M%S`;

	$date =~ s/\R//g;

	return $date; 
}

sub getLastBackupDate
{
	my ($folder) = @_;

	my @files = <$folder/backup.*>;

	foreach $file (@files)
	{
        	$file =~ /.*\.(\d+)$/;

        	push @backupDates, $1;
	}

	my @backupDates = sort(@backupDates);

	return $backupDates[$#backupDates];
}

sub syncStaging
{
	my ($hostname, $sshKey, $serverFolder, $localFolder) = @_;	

	executeCommand("rsync -avz --delete --rsh=\"ssh -i $sshKey\" " .
		"root\@${hostname}:$serverFolder $localFolder");
}

sub rotateBackup
{
	my ($backupBase, $lastBackupDate, $newBackupDate) = @_;

	executeCommand("rsync -a --delete " . 
		"--link-dest=$backupBase/backup.$lastBackupDate " .
		"$backupBase/staging/ " .
		"$backupBase/backup.$newBackupDate/");
}

sub calculateBackupSize
{
	my ($hostname, $backupBase, $backupFolder) = @_;

	executeCommand("du -s -B 1 $backupBase/$backupFolder"); 
}

sub executeCommand
{
	my ($command) = @_;

	if ($debug)
	{
		print($command . "\n");
	}
	else
	{
		system($command);
	}
}

1;


 

