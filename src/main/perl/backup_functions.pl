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


 

