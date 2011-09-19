.. _example:

Examples
========================

.. contents::
   :backlinks: none
   :local:


Reliable log forwarding (active-backup)
-----------------------------------------------------

This example assumes following network::

                       active log server
                       +--------+
                    +--> fluent | 192.168.0.1
    front server    |  +--------+
    +--------+      |
    | fluent -------+
    +--------+      |  backup log server
                    |  +--------+
                    +--> fluent | 192.168.0.2
                       +--------+

On the front servers, use following configuration::

    <match PATTERN>
      type tcp
      host 192.168.0.1
      port 24224
    
      # use file buffer to buffer events on disks.
      buffer_type file
      buffer_path /var/log/fluent/buffer/myforward
    
      # use longer flush_interval to reduce CPU usage.
      # this is trade-off of latency.
      flush_interval 60s
    
      # use secondary host
      <secondary>
        host 192.168.0.2
        port 24224
      </secondary>
    </match>

On the log servers, add ``tcp`` input not exists::

    <source>
      type tcp
      port 24224
    </source>

Reliable log forwarding (active-active)
-----------------------------------------------------

You can use active-active formation by using following configuration on the front servers::

    <match PATTERN>
      # use 'roundrobin' output plugin
      type roundrobin
    
      <store>
        type tcp
        host 192.168.0.1
        port 24224
    
        buffer_type file
        buffer_path /var/log/fluent/buffer/myforward-1
        flush_interval 60s
    
        <secondary>
          host 192.168.0.2
          port 24224
        </secondary>
      </store>

      <store>
        type tcp
        host 192.168.0.2
        port 24224
    
        buffer_type file
        buffer_path /var/log/fluent/buffer/myforward-2
        flush_interval 60s
    
        <secondary>
          host 192.168.0.1
          port 24224
        </secondary>
      </store>
    </match>


.. Calculate web accesses hourly and write it to MongoDB
.. -----------------------------------------------------
.. 
.. Writing plugin
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. Put following script to $install_prefix/etc/fluent/plugin directory::
.. 
..     # out_count_to_mongo.rb
..     class CountToMongoOutput < Fluent::TimeSlicedOutput
..       Fluent::Plugin.register_output('count_to_mongo', self)
..     
..       def initialize
..         require 'mongo'
..         super
..       end
..     
..       def configure(conf)
..         super
..     
..         @host = conf['host']
..         @port = (conf['port'] || @port).to_i
..         @database = conf['database']
..         @collection = conf['collection']
.. 
..         if !@host || !@database || !@collection
..           raise Fluent::ConfigError, "'host', 'database' and 'collection' parameters are required on count_to_mongo output"
..         end
..       end
..     
..       def start
..         super
..         @coll = Mongo::Connection.new(@host, @port)[@database][@collection]
..       end
..     
..       def format(tag, event)
..         event.record['path'].to_msgpack
..       end
..     
..       def write(chunk)
..         time = chunk.key  # get slike key (like "2011063023")
..     
..         counts = {}      # {path => count}
..         chunk.open {|io|
..           MessagePack::Unpacker.new(io).each {|path|
..             counts[path] = counts.fetch(path, 0) + 1
..           } rescue EOFError
..         }
..     
..         counts.each_pair {|path,count|
..           obj = {"time"=>time, "path"=>path, "count"=>count}
..           $log.trace { "count_to_mongo: inserting #{obj.to_json}" }
..           @coll.insert(obj)
..           # FIXME get last error?
..         }
..       end
..     end
.. 
.. Configuration
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. $install_prefix/etc/fluent/fluent.conf::
.. 
..     # read access log from /var/log/apache/access.log
..     <source>
..       type tail
..       format apache
..       path /var/log/apache/access.log
..       tag apache.access
..     </source>
..     
..     # configure count_to_mongo plugin
..     <match apache.access>
..       type count_to_mongo
..       host 127.0.0.1
..       database test
..       collection hourly_access
..     
..       # use file-based buffer
..       buffer_type file
..       buffer_path /tmp/fluent/count_to_mongo.*.buffer
..     
..       # write out buffered chunk hourly
..       time_slice hourly
..     
..       # expand limit of the chunk size from 1MB (default) to 100MB
..       buffer_chunk_limit 100m
..     </match>

