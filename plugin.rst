.. _plugin:

Plugins
========================

.. contents::
   :backlinks: none
   :local:

Type of plugins
------------------------------------

There are 3 types of plugins:

  Input plugin
    Provides an entrance of events. It usually creates a thread and listen socket. Or pull data from data sources periodically.

  Output plugin
    Provides an exit of events. Output plugins are usually *buffered* that accumulates events in the buffer and write out to file or network. Buffers are provided by buffer plugins.
    Some output plugins are fully customized plugin that doesn't use buffer plugins.

  Buffer plugin
    Provides a buffer implementation. Buffer plugin manages performance and reliability.

You can add your own plugin. See :ref:`devel`.


.. _input_plugin:

Input plugins
------------------------------------

http
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**http** input plugin listens HTTP clients. The URL is a tag of events and event body is included on the POST parameter.

+------------+------------------------------------------------------------------+----------------------------+
| Parameter  | Description                                                      | Required?                  |
+============+==================================================================+============================+
| json       | body of the event in JSON format                                 | either 'msgpack' or 'json' |
+------------+------------------------------------------------------------------+----------------------------+
| msgpack    | body of the event in `MessagePack <http://msgpack.org/>`_ format | either 'msgpack' or 'json' |
+------------+------------------------------------------------------------------+----------------------------+
| time       | time of the event in integer (UNIX time)                         | no                         |
+------------+------------------------------------------------------------------+----------------------------+

**example**::

    POST /myapp.access HTTP/1.1
    Content-Length: 21
    Content-Type: application/x-www-form-urlencoded
    
    json={"event":"body"}

**configuration**::

    <source>
      type http
      port 9880
      bind 0.0.0.0
      body_size_limit 32m
      keepalive_timeout 10s
    </source>

port
  port to listen on. Default is 9880.

bind
  bind address to listen on. Default is 0.0.0.0 (all addresses).

body_size_limit
  limit of the body size. Default is 32MB.

keepalive_timeout
  timeout of keep-alived connection. Default is 10 seconds.


tail
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**tail** input plugin reads events from the tail of text files, like ``tail -f`` command.

**configuration**::

    <source>
      type tail
      path /var/log/httpd-access.log
      tag apache.access
      format apache
    </source>

path (required)
  Paths separated with ',' to read. This parameter is required.

tag (required)
  Tag of the event. This parameter is required.

format (required)
  Format of the log. It's name of a template or regexp surround by '/'.

  Regexp must have at least one named captures (?<NAME>PATTERN). If the regexp has capture named 'time', it is used as a time of the event. You can specify format of the time using *time_format* parameter. If the regexp has capture named 'tag', *tag* parameter + captured tag is used as the tag of the event.

  Following templates are supported:

  apache
    Reads apache's log file *host*, *user*, *time*, *method*, *path*, *code*, *size*, *referer* and *agent* fields. This template is same as following configuration::

      format /^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$/
      time_format %d/%b/%Y:%H:%M:%S %z

  syslog
    Reads syslog's output file (e.g. /var/log/syslog) *time*, *host*, *ident*, *message* fields. This template is same as following configuration::

      format /^(?<time>[^ ]* [^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?[^\:]*\: *(?<message>.*)$/
      time_format %b %d %H:%M:%S

time_format
  Format of the time field. This parameter is required only if the format includes 'time' capture and it can't be parsed automatically.
  See `Time#strptime <http://www.ruby-doc.org/core-1.9/classes/Time.html#M000326>`_.


.. syslog
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. **syslog** inplut plugin receives logs from syslogd using UDP.
.. 
.. **configuration**::
.. 
..     <source>
..       type syslog
..       port 5140
..       bind 0.0.0.0
..       tag my.syslog
..     </source>
.. 
.. port
..   port to listen on. Default is 5140.
.. 
.. bind
..   bind address to listen on. Default is 0.0.0.0 (all addresses).
.. 
.. tag (required)
..   Tag of the event. This parameter is required.
..   The syslog input plugin adds facility and priority to the tag. So the actual tag will be like *my.syslog.kern.info* in above configuration.
.. 
.. To transfer logs from syslogd to fluent, add following line to /etc/syslog.conf or /etc/rsyslog.conf::
.. 
..    # match pattern    fluent host:port
..    *.*                @127.0.0.1:5140


tcp
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**tcp** input plugin listens MessagePack stream or encoded JSON stream on a TCP socket.
The MessagePack stream is used by ``fluent-cat`` command or other language bindings.

Protocol format::

    stream:
      message...

    message:
      [tag, time, record]
      or
      [tag, [[time,record], [time,record], ...]]
      (Note that later format is only supported by MessagePack Stream.)

    example:
      ["myapp.access", 1308466941, {"a"=>1}]
      or
      ["myapp.access", [1308466941, {"a"=>1}], [1308466942, {"b"=>2}]]

**configuration**::

    <source>
      type tcp
      port 24224
      bind 0.0.0.0
    </source>

port
  port to listen on. Default is 24224.

bind
  bind address to listen on. Default is 0.0.0.0 (all addresses).


unix
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**unix** input plugin listens MessagePack stream on a UNIX socket. This is used by ``fluent-cat`` command or other language bindings.

The format is same as ``tcp``.

**configuration**::

    <source>
      type unix
      path /var/run/fluent.sock
    </source>

path
  Path of the socket. Default is $install_prefix/var/run/fluent.sock.


.. _output_plugin:

Buffered output plugins
------------------------------------

Most of output plugins are *buffered* which accumulates new events on memory or files.

The structure of the buffer is a queue of chunks like following::

    queue
    +---------+
    |         |
    |  chunk <-- write events to the top chunk
    |         |
    |  chunk  |
    |         |
    |  chunk  |
    |         |
    |  chunk --> wirte out the bottom chunk
    |         |
    +---------+

When chunk size exceeds limit (*buffer_chunk_limit*) or specified time elapsed (*flush_interval*), new empty chunk is pushed.
The bottom chunk is wirtten out immediately when new chunk is pushed.

If it failed to write, the chunk is left in the queue and retried to write after seconds (*retry_wait*).
If the retry count is exceeds limit (*retry_limit*), the chunk is trashed. The wait time before retrying increases twice and twice (1.0sec, 2.0sec, 4.0sec, ...).
If the length of the queue exceeds limit (*buffer_queue_limit*), new events are rejected.

All buffered output plugins supports following parameters described above::

    <match pattern>
      buffer_type memory
      buffer_chunk_limit 16m
      buffer_queue_limit 64
      flush_interval 60s
      retry_limit 17
      retry_wait 1s
    </match>

*buffer_type* specifies the type of buffer plugin. Default is ``memory``.

Suffixes "s" (seconds), "m" (minutes), "h" (hours) can be used for *flush_interval* and *retry_wait*. *retry_wait* can be a decimal.

Suffixes "k" (KB), "m" (MB), "g" (GB) can be used for *buffer_chunk_limit*.


file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffered output plugin writes events to files.

**configuration**::

    <match pattern>
      type file
      path /var/log/fluent/myapp
      time_slice_format %Y%m%d
      time_slice_wait 10m
      time_format %Y%m%dT%H%M%S%z
      compress gzip
      utc
    </match>

path (required)
  Path of the file. Actual path becomes path + time + ".log". See also ``time_slice_format`` option descried below.

time_slice_format
  Format of the time in the file path. Following characters are replaced with values:
      +-----+------------------------------------------+
      | %Y  | Year with century                        |
      +-----+------------------------------------------+
      | %m  | Month of the year (01..12)               |
      +-----+------------------------------------------+
      | %d  | Day of the month (01..31)                |
      +-----+------------------------------------------+
      | %H  | Hour of the day, 24-hour clock (00..23)  |
      +-----+------------------------------------------+
      | %M  | Minute of the hour (00..59)              |
      +-----+------------------------------------------+
      | %S  | Second of the minute (00..60)            |
      +-----+------------------------------------------+
  Default is ``%Y%m%d`` which splits files every day. Use ``%Y%m%d%H`` to split files every hour.

time_slice_wait
  Wait time before flushing the buffer. Default is 10 minutes.

time_format
  Format of the time written in files. Default is ISO-8601.

utc
  Uses UTC for path formatting. Default is localtime.

compress
  Compress flushed files. Supported algorithm is gzip. Default is no-compression.

Note that this output plugin uses file buffer by default.


tcp
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffered output plugin forwards events to another fluent server.

**configuration**::

    <match pattern>
      type tcp
      host 192.168.1.3
      port 24224
      send_timeout 60s
      <secondary>
        host 192.168.1.4
        port 24224
      </secondary>
    </match>

host (required)
  IP address or host name to send events. This parameters is required.

port
  Port number of the host to send. Default is 24224.

<secondary>
  Backup destination whch is used when the primary destination is failed.


unix
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**unix** buffered output plugin forwards events to another fluent process on the same host.

**configuration**::

    <match pattern>
      type unix
      path /var/run/fluent.sock
    </match>

path (required)
  Path to the UNIX domain socket. This parameters is required.


Non-buffered output plugins
------------------------------------

copy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**copy** output plugin copies events to multiple outputs.

**configuration**::

    <match pattern>
      type copy

      <store>
        type file
        path /var/log/fluent/myapp1
        ...
      </store>
      <store>
        ...
      </store>
      <store>
        ...
      </store>
    </match>

<store>
  Specifies output plugin. The format is same as <match> directive.


roundrobin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**roundrobin** output plugin distributes events to multiple outputs using round-robin algorithm.

**configuration**::

    <match pattern>
      type roundrobin

      <store>
        type tcp
        host 192.168.1.21
        ...
      </store>
      <store>
        ...
      </store>
      <store>
        ...
      </store>
    </match>

<store>
  Specifies output plugin. The format is same as <match> directive.


stdout
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**stdout** output plugin prints event to the console.

**configuration**::

    <match pattern>
      type stdout
    </match>

This output plugin is for debugging.


null
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**roundrobin** output plugin just throw away events.

**configuration**::

    <match pattern>
      type null
    </match>


.. _buffer_plugin:

Buffer plugins
------------------------------------

memory
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**memory** buffer plugin provides fast buffer implementation.
It uses memory to store buffer chunks. Buffered events which can't be written soon are deleted when fluent is shut down.

**configuration**::

  <match pattern>
    buffer_type memory
  </match pattern>


file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffer plugin provides persistent buffer implementation.
It uses file to store buffer chunks.

**configuration**::

  <match pattern>
    buffer_type file
    buffer_path /var/log/fluent/myapp.*.buffer
  </match pattern>

buffer_path (required)
  Path to store buffer chunks. '*' is replaced with random characters.
  This parameter is required.


.. _search_plugin:

Searching plugins
------------------------------------

You can use following command to search plugins released on RubyGems::

   $ fluent-gem search -rd fluent-plugin

You can also find plugins at the `Fluent plugins <http://fluentd.org/plugin/>`_ page.

Type following command to install it::

   $ sudo fluent-gem install fluent-plugin-scribe

Next step: :ref:`devel`

