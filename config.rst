.. _config:

Configuration
========================

You can control the flow of event stream using the configuration file. It is stored on /etc/fluent/fluent.conf.
It describes the format of the file.

.. contents::
   :backlinks: none
   :local:

Configuration file
------------------------------------

Configuration file consists of **<source>** directives and **<match>** directives.

**<source>** describes an entrance of events, like ``http`` or ``tcp``.

**<match>** describes the match pattern of events and an exit of the matched events, like ``myapp.accesslog.*`` to ``file`` or ``system.error.*`` to ``mail``.

Overview of the configuration file will be like as following::

    # Read events from 24224/tcp
    <source>
      type tcp
      port 24224
    </source>
    
    # http://this.host:9880/myapp.access?json={"event":"data"}
    <source>
      type http
      path 9880
    </source>
    
    # Match events tagged with "myapp.access" and
    # store them to /var/log/fluent/access.%Y-%m-%d
    <match myapp.access>
      type file
      path /var/log/fluent/access
    </match>
    
    <match myapp.log.*>
      type file
      format /var/log/fluent/myapp.%Y-%m-%d.log
    
      buffer_type file
      buffer_path /var/log/fluent/myapp
    </match>

<source> directive
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

<source> directive must have ``type`` parameter that specifies name of the input plugin.

Next step: :ref:`input_plugin`


<match> directive
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

<source> directive must have match pattern and ``type`` parameter that specifies name of the output plugin.

Next step: :ref:`output_plugin`


init script examples
------------------------------------

Ubuntu upstart
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODO

Put the file on ``/etc/init/fluent``::

    description "Fluent event collector"
    author "Sadayuki Furuhashi"
    
    start on (net-device-up and local-filesystems and runlevel [2345])
    stop on runlevel [016]
    
    respawn
    respawn limit 10 5
    
    # The default of 5 seconds is too low to flush buffers
    kill timeout 60
    
    exec bash -c "/usr/bin/fluentd -c /etc/fluent/fluent.conf 2>&1 \| /usr/bin/cronolog /var/log/fluent.log /var/log/fluent/fluent.%Y_%m_%d.log"

`cronolog <http://cronolog.org/>`_ is used for logging error messages. Install it using ``apt-get install cronolog``.

