.. _install:

Installation
========================

.. contents::
   :backlinks: none
   :local:

A. Normal installation
------------------------------------

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


B. Gem installation
------------------------------------

If you have installed `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2, you can use RubyGems to download and install Fluent.

You can confirm installed Ruby's version as following::

    $ ruby --version
    ruby 1.9.2p180 (2011-02-18 revision 30909) [x86_64-darwin10.6.0]

If it says ruby 1.9.2 or above, use ``gem`` command to install fluent::

    $ sudo gem install fluent

Next step: :ref:`install/confirm`


C. Latest repository installation
------------------------------------

To install the latest development version from the `source repository <https://github.com/fluent/fluent>`_, prepare `Ruby <http://www.ruby-lang.org/>`_ >= 1.9.2 and run following commands::

    $ git clone https://github.com/fluent/fluent.git
    $ cd fluent
    $ rake
    $ gem install pkg/fluent-*.gem

Next step: :ref:`devel`


.. _install/confirm:

Confirm installation
------------------------------------

To confirm installation, create a temporal configuration file whose content is like below, and save it as 'fluent_tmp.conf'::

  <source>
    type tcp
    port 24224
  </source>

  <match *>
    type stdout
  </match>

Then, run following commands::

    $ fluentd -c fluent_tmp.conf -vv &
    $ echo '{"json":"message"}' | fluent-cat debug.test

The first command ``fluentd -c fluent_tmp.conf -vv`` starts fluentd with the prepared configuration file. ``-vv`` option is for verbose logging. The second command sends fluentd a message '{"json":"message"}' with a tag "debug.test". If the installation was successful, fluentd will output a log containing a tag and a message passed for fluent-cat::

 2011-07-10 16:49:50 +0900 debug.test: {"json":"message"}


Updating
------------------------------------

Once you installed, you can update to the latest version using following command::

    $ sudo fluent-gem install fluent

Next step: :ref:`config`

