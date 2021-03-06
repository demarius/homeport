[![Stories in Ready](https://badge.waffle.io/bigeasy/homeport.png?label=ready&title=Ready)](https://waffle.io/bigeasy/homeport)
# Homeport v1.0.5

*TK: Undocumented hotness: `ssh` and `rsync` hopping, image flattening, X
Windows, Apple Share.*

Homeport is a Dockerized Linux development environment. It creates Dockerized
shell environments that you can run anywhere that Docker runs. They are
lightweight and easy to distribute.

Homeport images contain your dependencies. You can `push` and `pull` them to
Docker Hub. You can  collect them and trade them with your friends. Your working
directories data is kept in a home directory so that your project dependences
are independent of your personal data.

Homeport is a great way to do dependency management. It avoids cluttering your
workstation with package utilities, locally running servers, and version
switchers. You can keep your Homebrew to a minimimum. You can do without a
locally running `mysql` and `memcached`. You can skip `rvm` all together.

You can design for containerization of your application at the outset, by
containerizing the development enviornment.

## Contributing

If you have suggestions, or general questions, please place them in [milestone
discussion](https://github.com/bigeasy/homeport/issues/1) before opening an
issue. Pull Requests are welcome, but we're trying to keep Homeport light.

## Requirements

You'll need an installation of Docker or Docker Machine.

Homeport runs on Linux and OS X.

You must manage your ssh keys using `ssh-agent`.

```console
$ ssh-add ~/.ssh/id_rsa
$ ssh-add -l
```

If you don't do this already, now's the time to learn.

## Installation

You can install on OS X using Homebrew.

```console
$ brew tap bigeasy/homebrew
$ brew install homeport
$ homeport hello
hello, world
```

On Linux you can use the bootstrap script to run Homeport from Docker.

```console
$ sudo bash -c "$(docker run --rm homeport/homeport script /usr/local/bin/homeport)"
$ homeport hello
```

Running Homeport from within Docker is going have a slight delay when you invoke
commands, but it's not so bad. Besides, one you get homeport up and running, you
can always run Homeport in Homeport which is really snappy.

## Creating an Image

Create an image with `homeport create <image>`. Add packages with `homeport
append <image>`.

```console
$ homeport create example
$ homeport append example formula/apt-get rsync zsh vim git
```

The `homeport create` command will create a default homeport Ubuntu image. You
then install packages by runing formulas. The formula you'll be using the most
often is the `formula/apt-get` formula.

```console
$ docker images | grep '\(REPOSITORY\|homeport\)'
REPOSITORY                  TAG          IMAGE ID       CREATED       VIRTUAL SIZE
homeport/image-example      latest       4268a86a11d5   9 minutes ago 459.8 MB
```

Images are created in the homeport repository namespace. You won't be able to
push to that repository. Homeport will push to your repository instead.

## Running Your Image

For now, you need to first create a home direcotry. This will create a home
directory with your public SSH key obtained from `ssh-agent`.

```
$ homeport home
```

Now you can start the homeport SSH server and connect to it via ssh.

```
$ homeport run example
$ homeport ssh example
```

You should drop into `bash`.

## Append with Formulas

You add packages by using `homeport append` to specify a formula that will alter
your image, adding packages or adjusting settings.

```
$ homeport append example formula/apt-get zsh
$ homeport append example formula/chsh /usr/bin/zsh
```

There is a growing set of formulas that are distrubuted with Homeport. The
`formula/apt-get` that installs packages on Ubuntu is most commonly used. There
are also formulas to install Ruby Gems, Python pips, and Perl modules.

## Customization via User Formulas

When you specify a formula with a relative path beginning with `formula/`,
Homeport will use one of the default formulas installed with homeport.

```
$ homeport append example formula/apt-get ruby-dev make
$ homeport append example formula/gem travis
```

The above uses the default formulas for `apt-get` and Ruby Gems.

You can create your own formulas and invoke them using `homeport append`.

Formulas are structured as directories containing an installation bundle. The
installation is performed by a program named `install` inside the directory.

An install script for Python pips would look like this.

```bash
#!/bin/bash

pip install "$@"
```

To create a formula for  Python's `pip`, create a formula directory named `pip`.
Then create an `install` program in that directory that invokes `pip`.

```
$ mkdir -p ~/formula/pip
$ cat <<EOF> ~/formula/pip/install
#!/bin/bash

pip install "$@"
EOF
$ cat ~/formula/pip/install
#!/bin/bash

pip install "$@"
$ chmod +x ~/formula/pip/install
```

You can now invoke the formula from `homeport append`.

```
$ homeport append example ~/formula/pip awscli
```

Remember that if you use `formula/` as the start of the formula path, Homeport
will always search for the formula in the Homeport distribution. If you really
want to use a formula that is relative to your current working directory, you
need to prefix the path with a dot.

```
$ cd ~
$ homeport append example ./formula/pip awscli
$ homeport append example formula/pip boto pygments
```

The first invocation of `homeport append` above uses your own custom `pip`
formula. The second invocation uses the `pip` formula that comes with Homeport.

## Hopping with `ssh` and `rsync`

*Ed: This is an outline.*

`ssh` is primary. With some environments, you might have to hop through a couple
of machines along the way.

```
$ homeport ssh alan@www.prettyrobots.com core@54.68.221.10 node
```

## Apple Sharing

If you want to browse your Homeport home directories from the Finder, you can
use Apple file sharing from Homeport. (Some assmebly required.)

```
$ homeport create netatalk
$ homeport append netatalk formula/netatalk
$ open $(homeport share apple)
```

You should now be looking at your home directory in Finder.

## Docker Machine Suggestions

I use Docker Machine (formerly Boot2docker) on my MacBook. Docker Machine
creates a Linux in VirtualBox to host Docker. That virtual machine it creates to
host Linux is modest. I find that I run out of space pretty quckly with the
default settings.

I use custom settings to create a larger Docker Machine Linux image.

```
docker-machine create -d virtualbox --virtualbox-memory 2048 --virtualbox-disk-size 50000 dev
docker-machine start dev
```

## Hacking

Notes to self, installing Vagrant to install Ubuntu.

```
$ brew tap phinze/homebrew-cask && brew install brew-cask
$ brew cask install vagrant
$ vagrant plugin install vagrant-vbox-snapshot
$ vagrant box add trusty https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
$ mkdir ~/homeport && cd ~/homeport
$ vagrant init trusty
```

You now need to add `config.ssh.forward_agent = true` to the `Vagrantfile`.

```
$ vagrant up
$ vagrant ssh
```

Install Docker on Ubuntu.

```
$ sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
$ echo deb https://apt.dockerproject.org/repo ubuntu-trusty main | sudo tee /etc/apt/sources.list.d/docker.list
$ sudo apt-get update
$ sudo apt-get purge -y lxc-docker*
$ sudo apt-get install -y docker-engine
$ sudo usermod -aG docker vagrant
$ docker run hello-world
```

## Whad we learn?

 * If there is some hard and fast shobboleth, break it. Candy falls out.
 * `ssh` does 80% (or more) of everything you'd ever need from the network.
 * `printf -v var '%q'` is how you do a level of indirection.
 * evaluate bash as a script using `-c` instead of piping, you get to use arguments.

What do we get for breaking the rules?

 * Add some daemons, like `rsyslog` and `bindfs` to make life easier.
 * Docker terminals intercept ctl+p which is vital to bash.
 * In Docker bash output new lines are crlf.
 * Forwarding your SSH agent is as big a chore as they come, bigger than
 forwarding docker itself.
