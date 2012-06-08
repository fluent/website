.. _plugin:

Plugins
========================

Plugins extend Fluentd's functionality. 

The user can use the standard plugins packaged with Fluentd, or can write their own plugins. For further information on writing additional plugins, please refer to :ref:`devel`.

For Fluentd to function properly, the user must enable at least one input plugin and at least one output plugin using the configuration file. For further information on the configuration file, please refer to :ref:`config`.

.. contents::
   :backlinks: none
   :local:

Types of plugins
------------------------------------

Fluentd has 3 types of plugins:

  Input plugin
    Defines an input source of events. 
    
    An input plugin typically creates a thread and a listen socket. It can also be written to periodically pull data from data sources. Please note that Fluentd does not restrict the user from creating input plugins with alternative implementations. 

  Output plugin
    Defines an output destination for events. 
    
    An output plugin is typically *buffered*. A buffered output plugin instructs Fluentd to accumulate event logs in a buffer before writing chunks of data out to a file or network. The buffer's behavior is defined by a separate buffer plugin. Different buffer plugins can be chosen for each output plugin. 
    
    Some output plugins are fully customized and do not use buffers.

  Buffer plugin
    Defines the implementation of a buffer. 
    
    The user should choose the appropriate buffer plugin for the desired combination of performance and reliability.



.. _input_plugin:

Input plugins
------------------------------------

http
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The **http** input plugin allows Fluentd to listen to HTTP clients. The URL becomes the *tag* of the Fluentd event log, and the POSTed body element becomes the *record* of the Fluentd event log.

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
  The port to listen on. 
  Default Value = 9880

bind
  The bind address to listen on. 
  Default Value = 0.0.0.0 (all addresses)

body_size_limit
  The limit of the body size. 
  Default Value = 32MB.

keepalive_timeout
  The timeout limit for keeping the connection alive. 
  Default Value = 10 seconds


tail
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
..I think an example would help.
The **tail** input plugin allows Fluentd to read events from the tail of text files. Its read behavior is analogous to the ``tail -F`` command.

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

rotate_wait
  in_tail does a bit more than "tail -F". When one is rotating a file, there is a possibility that some data might still need to be written to the
  old file as opposed to the new one. in_tail takes care of this by keeping a reference to the old file (even after it's been rotated) for some time
  before transitioning to the new file entirely (so that the data designated for the old file don't get lost). By default, this time interval is
  5 seconds. The rotate_wait parameter accepts a single integer which represents the number of seconds you want to set this time interval to. 

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
..    # match pattern    fluentd host:port
..    *.*                @127.0.0.1:5140


forward
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**forward** input plugin listens TCP socket to receive event stream, and also listens UDP socket to receive heartbeat message. This is used to receive event logs from other fluentd, ``fluent-cat`` command or client libraries.

**configuration**::

    <source>
      type forward
      port 24224
      bind 0.0.0.0
    </source>

port
  port to listen on (both TCP and UDP). Default is 24224.

bind
  bind address to listen on. Default is 0.0.0.0 (all addresses).


This plugin uses MessagePack for the protocol::

    stream:
      message...

    message:
      [tag, time, record]
      or
      [tag, [[time,record], [time,record], ...]]

    example:
      ["myapp.access", [1308466941, {"a"=>1}], [1308466942, {"b"=>2}]]


.. unix
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. **unix** input plugin listens MessagePack stream on a UNIX socket.
.. 
.. The format is same as ``tcp``.
.. 
.. **configuration**::
.. 
..     <source>
..       type unix
..       path /var/run/fluent.sock
..     </source>
.. 
.. path
..   Path of the socket. Default is $install_prefix/var/run/fluent.sock.


exec
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**exec** input plugin executes external program to receive or pull event logs. This reads TSV (tab separated values) from the stdout of the program.

You can run the program periodically or permanently. To run periodically, use ``run_interval`` parameter.


**configuration**::

  <source>
    type exec
    command cmd arg arg
    keys k1,k2,k3
    tag_key k1
    time_key k2
    time_format %Y-%m-%d %H:%M:%S
    run_interval 10s
  </source>

command (required)
  The command to execute. 

keys (required)
  Column names of the output TSV.

tag (required if ``tag_key`` is not specified)
  tag of the output events.

tag_key
  Name of the key to use as the event tag instead of the value in the event record. If this parameter is not specified, it uses the ``tag`` parameter.

time_key
  Name of the key to use as the event time instead of the value in the event record. If this parameter is not specified, it uses the current time.

time_format
  Format of the event time used when the ``time_key`` parameter is specified. Default is UNIX time (integer).

run_interval
  Runs the program periodically in the specified interval.


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
    |  chunk --> write out the bottom chunk
    |         |
    +---------+

When chunk size exceeds limit (*buffer_chunk_limit*) or specified time elapsed (*flush_interval*), new empty chunk is pushed.
The bottom chunk is written out immediately when new chunk is pushed.

If it failed to write, the chunk is left in the queue and retried to write after seconds (*retry_wait*).
If the retry count is exceeds limit (*retry_limit*), the chunk is trashed. The wait time before retrying increases twice and twice (1.0sec, 2.0sec, 4.0sec, ...).
If the length of the queue exceeds limit (*buffer_queue_limit*), new events are rejected.

All buffered output plugins supports following parameters described above::

    <match pattern>
      buffer_type memory
      buffer_chunk_limit 256m
      buffer_queue_limit 128
      flush_interval 60s
      retry_limit 17
      retry_wait 1s
    </match>

*buffer_type* specifies the type of buffer plugin. Default is ``memory``.

Suffixes "s" (seconds), "m" (minutes), "h" (hours) can be used for *flush_interval* and *retry_wait*. *retry_wait* can be a decimal.

Suffixes "k" (KB), "m" (MB), "g" (GB) can be used for *buffer_chunk_limit*.


file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffered output plugin writes events to files. By default, it writes into the file in daily basis (almost at 00:10). Before that, no files are created. If you want to output the logs hourly or minutely, please modify 'time_slice_format' value.

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
  Path of the file. Actual path becomes path + time + ".log". See also ``time_slice_format`` parameter descried below.

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


forward
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**forward** buffered output plugin forwards events to other fluentd servers.

This plugin supports load-balancing and automatic fail-over (a.k.a. active-active backup). If you want replication, use ``copy`` plugin described below.

It detects fault of a server using "φ accrual failure detector" algorithm. You can customize parameter of the algorithm.

When a fault server recovers, the plugin makes it available automatically after several seconds.


**configuration**::

    <match pattern>
      type forward
      send_timeout 60s
      recover_wait 10s
      heartbeat_interval 1s
      phi_threshold 8
      hard_timeout 60s

      <server>
        name myserver1
        host 192.168.1.3
        port 24224
        weight 60
      </server>
      <server>
        name myserver2
        host 192.168.1.4
        port 24224
        weight 60
      </server>
      ...

      <secondary>
        type file
        path /var/log/fluent/forward-failed
      </secondary>
    </match>

<server> (required at least one)
  Description of a server.

name
  Name of the server. This parameter is used in error messages.

host (required)
  IP address or host name of the server. This parameters is required.

port
  Port number of the host. Default is 24224. Note that both TCP packets (event stream) and UDP packets (heartbeat message) are sent to this port.

weight
  Weight of load balancing. For example, weight of a server is 20 and weight of the other server is 30, events are sent in 2:3 raito. Default is 60.

send_timeout
  Timeout time to send event logs. Default is 60 seconds.

recover_wait
  Wait time before accepting recovery of a fault server. Default is 10 seconds.

heartbeat_interval
  Interval of heartbeat packer. Default is 1 second.

phi_threshold
  Threshold parameter to detect fault of a server. Default is 8.

hard_timeout
  Hard timeout to detect failure of a server. Default is same as the ``send_timeout`` parameter.

<secondary>
  Backup destination which is used when all servers are not available. This parameter is optional.


.. unix
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. **unix** buffered output plugin forwards events to another fluentd process on the same host.
.. 
.. **configuration**::
.. 
..     <match pattern>
..       type unix
..       path /var/run/fluent.sock
..     </match>
.. 
.. path (required)
..   Path to the UNIX domain socket. This parameters is required.


exec
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The **exec** buffered output plugin passes events to an external program as a tab-separated value (TSV) file. 

The command is passed the location of a TSV file containing incoming events as its last argument.

**configuration**::

  <match pattern>
    type exec
    command cmd arg arg
    keys k1,k2,k3
    tag_key k1
    time_key k2
    time_format %Y-%m-%d %H:%M:%S
  </match>

command (required)
  A command to execute. The exec plugin passes the path of a TSV file as the last argument.

keys (required)
  Comma-separated keys to use in the TSV file.

tag_key
  Name of the key to use as the event tag instead of the value in the event record.

time_key
  Name of the key to use as the event time instead of the value in the event record.

time_format
  Format for event time used when the ``time_key`` parameter is specified. Default is UNIX time (integer).


exec_filter
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**exec_filter** buffered output plugin executes an external program, using events as input and reading new events from the program output.

It passes tab-separated values (TSV) to stdin and reads TSV from stdout.

**configuration**::

  <match pattern>
    type exec_filter
    command cmd arg arg
    in_keys k1,k2,k3
    out_keys k1,k2,k3,k4
    tag_key k1
    time_key k2
    time_format %Y-%m-%d %H:%M:%S
  </match>

command (required)
  A command to execute. The exec plugin passes a path of TSV file to the last argument.

in_keys (required)
  Comma-separated keys to use from the incoming event for the TSV input to the command.

out_keys (required)
  Comma-separated keys to use in processing the TSV output from the program.

tag_key
  Name of the key to use as the event tag instead of the value in the event record.

time_key
  Name of the key to use as the event time instead of the value in the event record.

time_format
  Format of the event time used when the ``time_key`` parameter is specified. Default is UNIX time (integer).


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

**null** output plugin just throw away events.

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
It uses memory to store buffer chunks. Buffered events which can't be written soon are deleted when fluentd is shut down.

**configuration**::

  <match pattern>
    buffer_type memory
  </match>


file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**file** buffer plugin provides persistent buffer implementation.
It uses file to store buffer chunks.

**configuration**::

  <match pattern>
    buffer_type file
    buffer_path /var/log/fluent/myapp.*.buffer
  </match>

buffer_path (required)
  Path to store buffer chunks. '*' is replaced with random characters.
  This parameter is required.


.. _search_plugin:

Searching plugins
------------------------------------

You can find plugins released on RubyGems at the `Fluentd plugins <http://fluentd.org/plugin/>`_ page.

You can also use following command to search plugins::

   $ fluent-gem search -rd fluent-plugin

Type following command to install it::

   $ sudo fluent-gem install fluent-plugin-scribe

Next step: :ref:`devel`

