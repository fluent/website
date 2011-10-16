.. _install:

Installation
============

.. contents::
   :backlinks: none
   :local:

Installation
------------

To install fluent, there're some ways: from 1) Gem, 2) .tar.gz, 3) git. The first one is recommended for most cases.

Install from Binary Package
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Currently, Treasure Data Inc. provides the stable distribution of fluent, called td-agent. It consists of the following components:

* Ruby interpreter
* Fluent
* Several plugins with stable & compatible versions

It's actively updated, and used in the production environments. To install it, please have a look at the following documentations.

* `Installing td-agent for Debian and Ubuntu <http://help.treasure-data.com/kb/installing-td-agent-daemon/installing-td-agent-for-debian-and-ubuntu>`_
* `Installing td-agent for Redhat and CentOS <http://help.treasure-data.com/kb/installing-td-agent-daemon/installing-td-agent-for-redhat-and-centos>`_

Please note that the server command is 'td-agent' instead of 'fluentd' in this case. And the config file is located at '/etc/td-agent/td-agent.conf'.

Install from Gem
^^^^^^^^^^^^^^^^

If you have installed `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2, you can use RubyGems to download and install Fluent. You can confirm installed Ruby's version as following::

    $ ruby --version
    ruby 1.9.2p180 (2011-02-18 revision 30909) [x86_64-darwin10.6.0]

It's recommended to use `rvm (Ruby Version Manager) <https://rvm.beginrescueend.com/>`_ to install ruby. Then, please use ``gem`` command to install fluentd::

    # system-wide ruby
    $ sudo gem install fluentd

    # via rvm
    $ gem install fluentd

Next step: :ref:`install/confirm`

Install from .tar.gz
^^^^^^^^^^^^^^^^^^^^

Before building the source package, make sure following libraries are installed:

+--------------+--------------------------------------+--------------------------------+
|              | Ubuntu/Debian install                | RedHat/CentOS install          |
+==============+======================================+================================+
| openssl      | ``apt-get install libssl-dev``       | ``yum install libssl-dev``     |
+--------------+--------------------------------------+--------------------------------+
| zlib         | ``apt-get install zlib1g-dev``       | ``yum install zlib-devel``     |
+--------------+--------------------------------------+--------------------------------+
| readline     | ``apt-get install libreadline6-dev`` | ``yum install readline-devel`` |
+--------------+--------------------------------------+--------------------------------+

Then download source package from the `Download <https://github.com/fluent/fluent/downloads>`_ page and extract it.

Finally, build and install using ./configure && make && sudo make install::

    $ ./configure
    $ make
    $ sudo make install

Above commands install Fluent to ``$prefix`` and Ruby to ``$prefix/lib/fluent/ruby``.

Next step: :ref:`install/confirm`

Install from Latest Repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To install the latest development version from the `source repository <https://github.com/fluent/fluentd>`_, prepare `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2 and run following commands::

    $ git clone https://github.com/fluent/fluentd.git
    $ cd fluentd
    $ rake
    $ gem install pkg/fluentd-*.gem

Next step: :ref:`install/confirm`

.. _install/confirm:

Confirm Installation
--------------------

To confirm installation, run following commands::

    $ fluentd --setup ./fluent
    $ fluentd -c ./fluent/fluent.conf -vv &
    $ echo '{"json":"message"}' | fluent-cat debug.test

The last command sends fluentd a message '{"json":"message"}' with "debug.test" tag. If the installation was successful, fluentd will output following message::

    2011-07-10 16:49:50 +0900 debug.test: {"json":"message"}


Update
------

Once you installed, you can update to the latest version by using the following command::

    $ sudo fluent-gem install fluentd

Next step: :ref:`config`

Next step: :ref:`devel`
