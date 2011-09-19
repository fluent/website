.. _overview:

Overview
========================

**Fluent** is an event collector service. It's said that Fluent is generalized version of syslogd, which can deal with JSON object for the log message.


Architecture
------------------------------------

Fluent collects events from various data sources and write tem to files, databases or other storages::

    +-------------------------------------------+
    |                                           |
    |  Web apps  ---+                +--> file  |
    |               |                |          |
    |               +-->          ---+          |
    |  /var/log  ------>  fluent  ------> mail  |
    |               +-->          ---+          |
    |               |                |          |
    |  apache    ---+                +--> S3    |
    |                                           |
    +-------------------------------------------+

Fluent also supports log transfer::

    Web server
    +--------+
    | fluent -------+
    +--------+      |
                    |
    Proxy server    |
    +--------+      +--> +--------+
    | fluent ----------> | fluent |
    +--------+      +--> +--------+
                    |
    Database server |
    +--------+      |
    | fluent -------+
    +--------+

An event collected consists of *tag*, *time* and *record*. Tag is a string separated with '.' (e.g. myapp.access). It is used to categorize events. Time is a UNIX time when the event occurs. Record is a JSON object.


Reliability
------------------------------------

Fluent provides reliable buffering strategy to prevent loss of events from failure of servers.

The structure of the buffer is a queue of chunks::

    queue
    +---------+
    |         |
    |  chunk <-- write events to the top chunk
    |         |  (never block)
    |  chunk  |
    |         |
    |  chunk  |
    |         |
    |  chunk --> wirte out the bottom chunk
    |         |  (transactional)
    +---------+

When a event is reached to a fluent server, it is appended to a top buffer chunk. This operation never blocks even if next server is down.

When size of the the top chunk exceeds limit or timer is expired, new empty chunk is pushed. And another thread get the bottom chunk and forward it to the next server (or send to a storage server). If it succeeded, the chunk is removed. Otherwise the thread leaves the chunk in the queue and retries to send it later.

The implementation of the buffer is pluggable. Default plugin named 'memory' stores chunks in memory. It is fast but not persistent. Another plugin named 'file' stores chunks in file.


Next step: :ref:`install`

