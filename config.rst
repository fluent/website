.. _config:

Configuration
========================

You can control the flow of event stream using the configuration file.  It describes the format of the file.

.. contents::
   :backlinks: none
   :local:

Configuration file
------------------------------------

Configuration file is stored on $install_prefix/etc/fluent/fluent.conf. If it not exist, create it using following command::

    $ sudo fluentd --setup /etc/fluent
    $ edit /etc/fluent/fluent.conf

Configuration file consists of **<source>** directives and **<match>** directives.

**<source>** describes an entrance of events, like ``http`` or ``tcp``.

**<match>** describes the match pattern of events and an exit of the matched events, like ``myapp.accesslog.**`` to ``file``.

Overview of the configuration file will be like as following::

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

<source> directive
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

<source> directive must have ``type`` parameter that specifies name of the input plugin.

Next step: :ref:`input_plugin`


<match> directive
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

<match> directive must have match pattern and ``type`` parameter that specifies name of the output plugin.

Next step: :ref:`output_plugin`

match pattern
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use following match patterns:

* ``*`` matches a tag element.

  * For example, pattern ``a.*`` matches ``a.b``, but not matches ``a`` or ``a.b.c``

* ``**`` matches zero or more tag elements.

  * For example, pattern ``a.**`` matches ``a``, ``a.b`` and ``a.b.c``

* ``{X,Y,Z}`` matches X, Y or Z, where X,Y,Z are patterns.

  * For example, pattern ``{a,b}`` matches ``a`` and ``b``, but not matches ``c``

  * You can use it with ``*`` and ``**`` patterns, like ``a.{b,c}.*`` or ``a.{b,c.**}``


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

