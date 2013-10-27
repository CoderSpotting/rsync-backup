hostname => "host.example.com",
sshKey => "/location/of/ssh/file/id_rsa",
folders => 
[
	{
        remoteFolder    => '/some/remote/folder/',
        localFolder     => 'some'
    },
    {
        remoteFolder    => '/some/other/remote/folder/',
        localFolder     => 'other'
    }
]