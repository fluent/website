.. _config:

Configuration File
========================

The configuration file allows the user to control the input and output behavior of Fluentd. This document describes the format of the file.

The configuration file is located at $install_prefix/etc/fluent/fluent.conf. If the file does not exist, the user must create it using the following commands::

    $ sudo fluentd --setup /etc/fluent
    $ edit /etc/fluent/fluent.conf

The configuration file must specify **<source>** directives and **<match>** directives.

.. contents::
   :backlinks: none
   :local:

<source> Directive
------------------

**<source>** specifies the accepted input sources for events. Common examples include ``http`` and ``tcp``.

<source> directive must have ``type`` parameter that specifies name of the input plugin.


    # Receive events from 24224/tcp
    # This is used by log forwarding and fluent-cat command
    <source>
      type tcp
      port 24224
    </source>
    
    # http://this.host:9880/myapp.access?json={"event":"data"}
    <source>
      type http
      port 9880
    </source>


Next step: :ref:`input_plugin`


<match> Directive
------------------

**<match>** specifies the match pattern of events and an exit for the matched events. For example, the user can send all matches to the pattern ``myapp.accesslog.**`` to ``file`` in a specified directory.

<match> directive must have match pattern and ``type`` parameter that specifies name of the output plugin.

# Match events tagged with "myapp.access" and
    # store them to /var/log/fluent/access.%Y-%m-%d
    <match myapp.access>
      type file
      path /var/log/fluent/access
    </match>
    
    <match myapp.log.**>
      type file
      format /var/log/fluent/myapp_hourly
      time_slice_format %Y%m%d%H
    </match>

Next step: :ref:`output_plugin`

Match Pattern
------------------

You can use following match patterns:

* ``*`` matches a tag element.

  * For example, pattern ``a.*`` matches ``a.b``, but not matches ``a`` or ``a.b.c``

* ``**`` matches zero or more tag elements.

  * For example, pattern ``a.**`` matches ``a``, ``a.b`` and ``a.b.c``

* ``{X,Y,Z}`` matches X, Y or Z, where X,Y,Z are patterns.

  * For example, pattern ``{a,b}`` matches ``a`` and ``b``, but not matches ``c``

  * You can use it with ``*`` and ``**`` patterns, like ``a.{b,c}.*`` or ``a.{b,c.**}``


Include
------------------

You can divide a config file into multiple files with 'include' directive.


    # Include config files in ./config.d directory
    include config.d/*.conf

It supports regular file path, glob pattern and http URL::

    # absolute path
    include /path/to/config.conf

    # if it is relative path, it use the dirname of this file
    # to expand the path
    include extra.conf

    # you can use glob match pattern
    include config.d/*.conf

    # also http
    include http://example.com/fluent.conf


.. Configuration

.. ========================
.. 
.. Shut down
.. ========================

.. Init scripts
.. ------------------------------------
.. 
.. Ubuntu upstart
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. Put the file on ``$install_prefix/etc/init/fluent``::
.. 
..     description "Fluent event collector"
..     author "Sadayuki Furuhashi"
..     
..     start on (net-device-up and local-filesystems and runlevel [2345])
..     stop on runlevel [016]
..     
..     respawn
..     respawn limit 10 5
..     
..     # The default of 5 seconds is too low to flush buffers
..     kill timeout 60
..     
..     exec bash -c "/usr/bin/fluentd -c /usr/local/etc/fluent/fluent.conf 2>&1 \| /usr/bin/cronolog /var/log/fluent.log /var/log/fluent/fluent.%Y_%m_%d.log"
.. 
.. `cronolog <http://cronolog.org/>`_ is used for logging error messages. Install it using ``apt-get install cronolog``.
.. 
.. TODO

