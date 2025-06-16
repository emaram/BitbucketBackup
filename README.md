# README #

This script makes a full backup (**_git clone --mirror_**) for all repositories in all projects.
You can also make backup to a specific number of projects, by setting up the i variable in **backup.sh**

### Credentials ###

Add your Bitbucket credentials in **credentials.info** file, encoding it base64.
>Credentials must be in format:
>>username:token
>... where token is generated from Bitbucket.

Run the following command to save your credentials:
>echo -n 'username:token' | base64 > credentials.info

### Bitbucket Space ###

Just like for credentials, add Bitbucket space name in **bitbucket.space** file.

Run the following command:
>echo -n  'bitbucketspacename' > bitbucket.space


### Launch backup ###

Make backup.sh, parseprojects.sh and parserepository.sh executable
>chmod +x backup.sh parseprojects.sh parserepository.sh

Launch backup
>./backup.sh

If you want to lunch the backup and leave it running, even if you close the shell
>nohup ./backup.sh


