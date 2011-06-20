.. _overview:

Overview
========================

**Fluent** is an event collector service. It's said that Fluent is generalized version of syslogd, which can deal with JSON object for the log message.


Architecture
------------------------------------

Fluent collects events from various data sources and write tem to files, database or other storages::

    Web apps  ---+                +--> file
                 |                |
                 +-->          ---+
    /var/log  ------>  fluent  ------> mail
                 +-->          ---+
                 |                |
    apache    ----                +--> fluent

Fluent also supports log transfer (not implemented yet)::

    Web server
    +--------+
    | fluent -------
    +--------+|     |
     +--------+     |
                    |
    Proxy server    |    Log server, Amazon S3, HDFS, ...
    +--------+      +--> +--------+
    | fluent ----------> | fluent ||
    +--------+|     +--> +--------+|
     +--------+     |     +--------+
                    |
    Database server |
    +--------+      |
    | fluent ---------> mail
    +--------+|
     +--------+

An event collected consists of *tag*, *time* and *record*. Tag is a string separated with '.' (e.g. myapp.access). It is used to categorize events. Time is a UNIX time when the event occurs. Record is a JSON object.


Next step: :ref:`install`

