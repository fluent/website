.. _config:

Configuration File
========================

The configuration file allows the user to control the input and output behavior of Fluentd by (1) selecting input and output plugins and (2) specifying the plugin parameters. The file is required for Fluentd to operate properly.

The configuration file is located at $install_prefix/etc/fluent/fluent.conf. If the file does not exist, the user must create it using the following commands::

    $ sudo fluentd --setup /etc/fluent
    $ edit /etc/fluent/fluent.conf

The configuration file must include the following:

1. **<source>** directives which determine the input sources.
2. **<match>** directives which determine the output destinations.

This document describes the format of the file.

.. contents::
   :backlinks: none
   :local:

<source> Directive
------------------

Fluentd's input sources are enabled by selecting and configuring the desired input plugins using **<source>** directives. Fluentd's standard input plugins include ``http`` and ``forward``. 

Each **<source>** directive must include a ``type`` parameter. The ``type`` parameter specifies the chosen input plugin. 

Examples::

    # Receive events from 24224/tcp
    # This is used by log forwarding and fluent-cat command
    <source>
      type forward
      port 24224
    </source>
    
    # http://this.host:9880/myapp.access?json={"event":"data"}
    <source>
      type http
      port 9880
    </source>

The user can expand Fluentd's input sources beyond those provided initially by writing their own plugins. For further information regarding Fluentd's input sources, please refer to :ref:`input_plugin`.

Sources submit events into the Fluentd's routing engine. An event consists of three entities: **tag**, **time** and **record**. Tag is a string separated by '.' (e.g. myapp.access), and is used to Fluentd's internal routing engine. Time is the UNIX time when the event occurs. Record is a JSON object. In the above example, the forward plugin submits the following event::

    tag: myapp.access
    time: (current time)
    record: {"event":"data"}


<match> Directive
------------------

Fluentd's output destinations are enabled by selecting and configuring the desired output plugins using **<match>** directives. Fluentd's standard output plugins include ``file`` and ``forward``. 

Each **<match>** directive must include a match pattern and a ``type`` parameter. Match patterns are used to filter the events. Only the events whose **tag** matches the pattern will be sent to the output destination. The ``type`` parameter specifies the chosen output plugin.

For example, the user can send all matches to the pattern ``myapp.accesslog.**`` to ``file`` in a specified directory.

Examples::

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

The user can expand Fluentd's input sources beyond those provided initially by writing their own plugins. For further information regarding Fluentd's output destinations, please refer to :ref:`output_plugin`

Match Pattern
^^^^^^^^^^^^^

The following match patterns are available to the user:

* ``*`` matches a single tag element.

  * For example, pattern ``a.*`` matches ``a.b``, but does not match ``a`` or ``a.b.c``

* ``**`` matches zero or more tag elements.

  * For example, pattern ``a.**`` matches ``a``, ``a.b`` and ``a.b.c``

* ``{X,Y,Z}`` matches X, Y, or Z, where X, Y, and Z are match patterns.

  * For example, pattern ``{a,b}`` matches ``a`` and ``b``, but does not match ``c``

  * This can be used in combination with the ``*`` or ``**`` patterns. Examples include ``a.{b,c}.*`` and ``a.{b,c.**}``


Include
------------------

Directives in separate configuration files can be imported using the **include** directive::

    # Include config files in ./config.d directory
    include config.d/*.conf

The **include** directive supports regular file path, glob pattern, and http URL conventions::

    # absolute path
    include /path/to/config.conf

    # if using a relative path, the directive will use 
    # the dirname of this file to expand the path
    include extra.conf

    # glob match pattern
    include config.d/*.conf

    # http
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
..     description "Fluentd event collector"
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

Next step: :ref:`plugin`

