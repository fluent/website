.. _plugin:

Plugins
========================

.. contents::
   :backlinks: none
   :local:

Kind of plugins
------------------------------------

There are 3 kinds of plugins:

  Input plugin
    Adds new entrance of events. It usually create a thread and listen a socket. Or pull data from data sources periodically.

  Output plugin
    Adds new exit of events. Output plugins are usually *buffered output* that accumulates events in the buffer and write out to file or network. The buffers are provided by buffer plugins.
    Some output plugins are fully customized plugin that doesn't use buffer plugins.

  Buffer plugin
    Adds new buffer implementation. Buffer plugin manages performance and reliability.


.. _input_plugin:

Input plugins
------------------------------------

http
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**http** input plugin listens HTTP clients. The URL is a tag of events and event body is included on the POST parameter::

    POST /myapp.access HTTP/1.1
    Content-Length: 21
    Content-Type: application/x-www-form-urlencoded
    
    json={"event":"body"}

+------------+------------------------------------------------------------------+----------------------------+
| Parameter  | Description                                                      | Required?                  |
+============+==================================================================+============================+
| json       | body of the event in JSON format                                 | either 'msgpack' or 'json' |
+------------+------------------------------------------------------------------+----------------------------+
| msgpack    | body of the event in `MessagePack <http://msgpack.org/>`_ format | either 'msgpack' or 'json' |
+------------+------------------------------------------------------------------+----------------------------+
| time       | time of the event in integer (UNIX time)                         | no                         |
+------------+------------------------------------------------------------------+----------------------------+

**configuration**::

    <source>
      type http
      port 9880
      bind 0.0.0.0
    </source>

port
  port to listen on. Default is 9880.

bind
  bind address to listen on. Default is 0.0.0.0 (all addresses).

tcp
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**tcp** input plugin listens MessagePack stream on a TCP socket. This is used by ``fluent-cat`` command or other language bindings.

Protocol format::

    stream:
      message...

    message:
      [tag, time, record]
      or
      [tag, [[time,record], [time,record], ...]]

    example:
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

Output plugins
------------------------------------

Buffered outputs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Most of output plugins are *buffered output* that accumulates events in the buffer and write out to file or network. The buffers are provided by buffer plugins.

The *buffer* is a queue of chunks::

    queue
    +---------+
    |         |
    |  chunk <-- write events to the top chunk.
    |         |
    |  chunk  |
    |         |
    |  chunk  |
    |         |
    |  chunk --> wirte out the bottom chunk
    |         |
    +---------+

When chunk size exceeds limit (*buffer_chunk_limit*) or specified time elapsed (*buffer_flush_interval*), new empty chunk is pushed.
The bottom chunk is wirtten out immediately when new chunk is pushed.

If it failed to write, the chunk is left in the queue and retried to write after seconds (*retry_wait*).
If the retry count is exceeds limit (*retry_limit*), the chunk is trashed. The wait time before retrying increases twice and twice (1.0sec, 2.0sec, 4.0sec, ...).
If the length of the queue exceeds limit (*buffer_queue_limit*), new events are rejected.

All buffered output plugins supports following parameters described above::

    <match pattern>
      buffer_type memory
      buffer_flush_interval 60s
      buffer_chunk_limit 1m
      buffer_queue_limit 100
      retry_limit 10
      retry_wait 1.0s
    </match>

*buffer_type* specifies the type of buffer plugin. Default is ``memory``.

Suffixes "s" (seconds), "m" (minutes), "h" (hours) can be used for *buffer_flush_interval* and *retry_wait*. *retry_wait* can be a decimal.

Suffixes "k" (KB), "m" (MB), "g" (GB) can be used for *buffer_chunk_limit*.



file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffered output plugin writes events to files.

**configuration**::

    <match pattern>
      type file
      path /var/log/fluent/myapp
      format /var/log/fluent/myapp.%Y-%m-%d-%H.log
      localtime
    </match>

path
  Syntax sugar for ``$path.%Y-%m-%d-%H``.
  Either format or path parameter is required.

format
  Path of the file. Following characters is replaced with values:

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

localtime
  Uses local time zone for path formatting. Default is UTC.

copy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**copy** output plugin copies events to multiple outputs. This is NOT buffered plugin.

**configuration**::

    <match pattern>
      <store>
        type file
        path /var/log/fluent/myapp1
        ...
      </store>
      <store>
        type file
        path /var/log/fluent/myapp2
        ...
      </store>
      ...
    </match>

<store>
  Specifies output plugin. The format is same as <match> directive.


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

