.. _install:

Installation
============

.. contents::
   :backlinks: none
   :local:

Installation
------------

The user can install Fluentd from four sources.

* Binary package
* RubyGems
* .tar.gz 
* Git repository

In most cases, installing from the binary package is recommended. 

Install from Binary Package
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Treasure Data Inc. provides the stable distribution of Fluentd, called td-agent. If you don't want to install Ruby interpreter (> 1.9.2) by yourself and don't want to manage Fluentd + plugins versions, using td-agent is the recommended way.

td-agent consists of the following components:

* Ruby interpreter, dedicated to Fluentd
* Fluentd
* Several plugins with stable & compatible versions

td-agent is actively maintained and is used within production environments. For details on installing td-agent, please refer to the following documents:

* `Installing td-agent for Debian and Ubuntu <http://help.treasure-data.com/kb/installing-td-agent-daemon/installing-td-agent-for-debian-and-ubuntu>`_
* `Installing td-agent for Redhat and CentOS <http://help.treasure-data.com/kb/installing-td-agent-daemon/installing-td-agent-for-redhat-and-centos>`_

Please note that if Fluentd is installed via td-agent, the server command will be 'td-agent' instead of 'fluentd'. The config file is located at '/etc/td-agent/td-agent.conf'.

Install from RubyGems
^^^^^^^^^^^^^^^^^^^^^

In order to install Fluentd via RubyGems, first install `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2. We recommend using `rvm (Ruby Version Manager) <https://rvm.beginrescueend.com/>`_ to install Ruby. The installed Ruby version can be confirmed as follows::

    $ ruby --version
    ruby 1.9.2p180 (2011-02-18 revision 30909) [x86_64-darwin10.6.0]

Once `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2 is installed, use the ``gem`` command as follows::

    # system-wide ruby
    $ sudo gem install fluentd

    # via rvm
    $ gem install fluentd

Next step: :ref:`install/confirm`

Install from .tar.gz
^^^^^^^^^^^^^^^^^^^^

Before building the source package, please ensure that the following libraries are already installed:

+--------------+--------------------------------------+--------------------------------+
|              | Ubuntu/Debian install                | RedHat/CentOS install          |
+==============+======================================+================================+
| openssl      | ``apt-get install libssl-dev``       | ``yum install libssl-dev``     |
+--------------+--------------------------------------+--------------------------------+
| zlib         | ``apt-get install zlib1g-dev``       | ``yum install zlib-devel``     |
+--------------+--------------------------------------+--------------------------------+
| readline     | ``apt-get install libreadline6-dev`` | ``yum install readline-devel`` |
+--------------+--------------------------------------+--------------------------------+

Next, download the source package from the `Download <https://github.com/fluent/fluentd/downloads>`_ page and extract it.

Finally, build and install using the following commands::

    $ ./configure
    $ make
    $ sudo make install

The commands above will install Fluentd to ``$prefix`` and Ruby to ``$prefix/lib/fluent/ruby``.

Next step: :ref:`install/confirm`

Install from Latest Git Repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To install the latest development version of Fluentd from the `source repository <https://github.com/fluent/fluentd>`_, prepare `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2 and run the following commands::

    $ git clone https://github.com/fluent/fluentd.git
    $ cd fluentd
    $ rake
    $ gem install pkg/fluentd-*.gem

Next step: :ref:`install/confirm`

.. _install/confirm:

Confirm Installation
--------------------

To confirm that Fluentd was installed successfully, run the following commands::

    $ fluentd --setup ./fluent
    $ fluentd -c ./fluent/fluent.conf -vv &
    $ echo '{"json":"message"}' | fluent-cat debug.test

The last command sends Fluentd a message '{"json":"message"}' with a "debug.test" tag. If the installation was successful, Fluentd will output the following message::

    2011-07-10 16:49:50 +0900 debug.test: {"json":"message"}


Update
------

Once Fluentd is installed, the following command will update it to the latest version::

    $ sudo fluent-gem install fluentd

Next step: :ref:`config`

Next step: :ref:`devel`
