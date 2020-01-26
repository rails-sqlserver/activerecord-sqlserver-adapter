# A Virtual Machine for ActiveRecord SQL Server Adapter Development

## Introduction

**Please note this VM is _not_ designed for Rails application development with MS SQL Server, only ActiveRecord SQL Server core development.**

Microsoft now supports running MS SQL Server server and the command-line tool `sqlcmd` on Linux. This document describes how to use a virtual machine for working on the ActiveRecord SQL Server adapter itself. Use this virtual machine to work on a pull request with everything ready to hack and run the test suites, including an instance of MS SQL Server running in the virtual machine. No more setting up and running a Windows VM, or developing on your company's MS SQL Server instance.

## Requirements

You must install the following on your development machine:

* [VirtualBox](https://www.virtualbox.org)
* [Vagrant 2](http://vagrantup.com)

You will need about 10 GB free space for each instance of the virtual machine that you want to use. You also need 4 GB of RAM in addition to whatever else you're running on your host.

## How To Build The Virtual Machine

Building the virtual machine is this easy:

    host $ mkdir mssql # Or whatever name suits you
    host $ cd mssql
    host $ vagrant jadesystems/rails-jade-18-04-mssql
    host $ vagrant up

That's it.

After the installation has finished, you can access the virtual machine with

    host $ vagrant ssh
    Welcome to Ubuntu 18.04 (GNU/Linux 5.0.0-32-generic x86_64)
    ...
    ubuntu@mssql:~$

Once in the virtual machine, you have to create the databases and user. First, log in as the `sa` account, using `sqlcmd`:

```bash
sqlcmd -S localhost -U sa -P MSSQLadmin!
```

or `sqsh`:

```bash
sqsh -S localhost -U sa -P MSSQLadmin!
```

Now follow the instructions in the "Creating the test databases" section of [Running Unit Tests](/RUNNING_UNIT_TESTS.md).

## RAM and CPUs

By default, the VM launches with 4 GB of RAM and 1 CPU. Consult the [Vagrant documentation](http://docs.vagrantup.com/v2/) if you want to change these parameters. Our experience is that you need at least 4 GB of RAM for the MS SQL Server virtual machine.

## What's In The Box

* Development tools for building gems needed for Rails and MS SQL Server
* Git
* Ruby 2.5
* Bundler
* MS SQL Server 2017
* TinyTDS and associated packages
* `sqsh` and `sqlcmd` for command-line access to MS SQL Server (as of this writing, Microsoft doesn't offer its GUI tools for Linux, and at any rate, the virtual machine is command-line only.)

## Recommended Workflow

The recommended workflow is

* edit in the host computer and
* test within the virtual machine.

This workflow is convenient because on the host computer you normally have your editor of choice fine-tuned, Git configured, and SSH keys in place.

Just clone your ActiveRecord SQL Server Adapter fork into the activerecord-sqlserver-adapter directory on the host computer:

    host $ cd mssql # Or whichever directory you created above
    host $ git clone git@github.com:<your username>/activerecord-sqlserver-adapter.git

Install gem dependencies in the _cloned_ directory:

    ubuntu@mssql:~$ cd /vagrant/activerecord-sqlserver-adapter
    ubuntu@mssql:/vagrant/activerecord-sqlserver-adapter$ bundle

We are ready to go to edit in the host, and test in the virtual machine.

Vagrant mounts your current directory on the host as _/vagrant_ within the virtual machine. That means, for example, you can run your editor on your host machine, with all your settings as you like it, and edit files in the virtual machine:

    host $ cd mssql # Or whichever directory you created above
    host $ code . # Or whatever editor you use

Port 3000 in the host computer is forwarded to port 3000 in the virtual machine. Thus, applications running in the virtual machine can be accessed via localhost:3000 in the host computer. Be sure the web server is bound to the IP 0.0.0.0, instead of 127.0.0.1, so it can access all interfaces. In the virtual machine, start the server like this:

    ubuntu@mssql:/vagrant/activerecord-sqlserver-adapter$ bin/rails server -b 0.0.0.0

Also, if you need to run the Rails server or anything else that takes advantage of Rails' auto-reloading of changed files, you also have to comment out one line and put another near the end of `config/environments/development.rb`:

    # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
    config.file_watcher = ActiveSupport::FileUpdateChecker

Now please go back to the [Running Unit Tests](/RUNNING_UNIT_TESTS.md) guide for how to set up databases and run test suites, etc.

## Virtual Machine Management

When done just log out with `^D` or `exit` and suspend the virtual machine

    host $ vagrant suspend

then, resume to continue development

    host $ vagrant resume
    host $ vagrant ssh

Run

    host $ vagrant halt

to shutdown the virtual machine, and

    host $ vagrant up

to boot it again.

You can find out the state of a virtual machine anytime by invoking

    host $ vagrant status

Finally, to completely wipe the virtual machine from the disk **destroying all its contents**:

    host $ vagrant destroy # DANGER: all is gone

Please check the [Vagrant documentation](http://docs.vagrantup.com/v2/) for more information on Vagrant.

## Faster Rails test suites

The default mechanism for sharing folders is convenient and works out the box in
all Vagrant versions, but there are a couple of alternatives that are more
performant.

### rsync

Vagrant 1.5 implements a [sharing mechanism based on rsync](https://www.vagrantup.com/blog/feature-preview-vagrant-1-5-rsync.html)
that dramatically improves read/write because files are actually stored in the
guest. Just throw

    config.vm.synced_folder '.', '/vagrant', type: 'rsync'

to the _Vagrantfile_ and either rsync manually with

    vagrant rsync

or run

    vagrant rsync-auto

for automatic syncs. See the post linked above for details.

### NFS

If you're using Mac OS X or Linux you can increase the speed of test suites with Vagrant's NFS synced folders.

With an NFS server installed (already installed on Mac OS X), add the following to the Vagrantfile:

    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
    config.vm.network 'private_network', ip: '192.168.50.4' # ensure this is available

Then

    host $ vagrant up

Please check the Vagrant documentation on [NFS synced folders](http://docs.vagrantup.com/v2/synced-folders/nfs.html) for more information.

## Troubleshooting

Check the [troubleshooting documentation for the virtual machine](https://github.com/lcreid/rails-5-jade#troubleshooting).

## Acknowledgement and Credits

This apporach was inspired by the Rails core team's approach to development, and large parts of this document were copied from https://github.com/rails/rails-dev-box.

## License

Released under the MIT License, Copyright (c) 2020-<i>ω</i> Larry Reid.
