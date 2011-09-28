.. _overview:

Overview
========================

Many web/mobile applications generate huge amount of **event logs** (c,f. login, logout, purchase, follow, etc). To analyze these event logs could be really valuable for improving the service. However, the challenge is collecting these logs seasily and reliably.

**Fluent** is an event collector daemon for solving that problem by having:

* Easy Installtion
* Small Footprint
* Flexible Plugin Mechanism
* Reliable Buffering
* Log Forwarding

Easy Installation
-----------------

**Fluent** is packaged as Ruby gem. You can install it by just one command.

Small Footprint
---------------

The core part of Fluent consists of only about 2,000 lines of Ruby, because of its simple architecture. Fluent collects events from various **input** sources and write them to **output** sinks.

The examples of input is: HTTP, Syslog, Apache Log, etc. And the examples of output is: Files, Mails, RDBMS databases, NoSQL storages.

This figure shows the basic idea of **input** and **output**::

        Input                          Output
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

An collected event consists of *tag*, *time* and *record*. Tag is a string separated with '.' (e.g. myapp.access). It is used to categorize events. Time is a UNIX time when the event occurs. Record is a JSON object.

Flexible Plugin Mechanism
-------------------------

The input and output can also be written in Ruby, and publishable by Ruby gems. You can search the available plugins by the following command::

  $ gem search -r fluent-plugin

Reliabile Buffering
-------------------

Sometimes writing the collected events to output fails by unexpected causes like network failure. That means the loss of the events. To prevent this problem, Fluent provides reliable buffering strategy. Fluent has a buffer, consisted of a queue of chunks, to temporarily store the collected events::

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

Log Forwarding
--------------

To analyze the event logs later, these are usually collected into one place. Fluent supports the log transfer functinality, to collect logs from various nodes, to the central server.::

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

Next step: :ref:`install`
