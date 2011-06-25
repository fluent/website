.. _example:

Examples
========================

.. contents::
   :backlinks: none
   :local:

Calculate web accesses hourly and write it to MongoDB
-----------------------------------------------------

Writing plugin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Put following script to $install_prefix/etc/fluent/plugin directory::

    # out_hourly_mongo.rb
    class HourlyMongoOutput < Fluent::BufferedOutput
      Fluent::Plugin.register_output('hourly_mongo', self)
    
      def initialize
        require 'mongo'
        @host = nil
        @port = 27017
        @database = nil
        @collection = nil
      end
    
      def configure(conf)
        super(conf)
    
        @host = conf['host']
        unless @host
          raise Fluent::ConfigError, "'host' parameter is required on hourly_mongo output"
        end
    
        @port = (conf['port'] || @port).to_i
    
        @database = conf['database']
        unless @database
          raise Fluent::ConfigError, "'database' parameter is required on hourly_mongo output"
        end
    
        @collection = conf['collection']
        unless @collection
          raise Fluent::ConfigError, "'collection' parameter is required on hourly_mongo output"
        end
      end
    
      def start
        super()
        @coll = Mongo::Connection.new(@host, @port)[@database][@collection]
      end
    
      def format(tag, event)
        [event.time, event.record['path']].to_msgpack
      end
    
      HOUR = 60*60
    
      def write(chunk)
        counts = {}  # (time/HOUR,path) => count
        chunk.open {|io|
          u = MessagePack::Unpacker.new(io)
          u.each {|time,path|
            next if !time || !path
            key = [time/HOUR, path]
            n = counts[key] || 0
            counts[key] = n + 1
          } rescue EOFError
        }
    
        counts.each_pair {|(hour,path),count|
          time = hour*HOUR
          obj = {"time"=>time, "path"=>path, "count"=>count}
          $log.trace { "hourly_mongo: inserting #{obj.to_json}" }
          @coll.insert(obj)
          # FIXME get last error?
        }
      end
    end

Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

$install_prefix/etc/fluent/fluent.conf::

    # read access log from /var/log/apache/access.log
    <source>
      type tail
      format apache
      path /var/log/apache/access.log
      tag apache.access
    </source>
    
    # configure hourly_mongo plugin
    <match apache.access>
      type hourly_mongo
      host 127.0.0.1
      database test
      collection hourly
    
      # use file-based buffer
      buffer_type file
      buffer_path /tmp/fluent/hourly_mongo.*.buffer
    
      # write out buffered chunk every 1 hour
      buffer_flush_interval 1h
    
      # expand limit of the chunk size from 1MB (default) to 100MB
      buffer_chunk_limit 100m
    </match>

