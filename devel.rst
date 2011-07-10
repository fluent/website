.. _devel:

Writing plugins
========================

.. contents::
   :backlinks: none
   :local:

Installing plugins
------------------------------------

To install a plugin, put a ruby script to ``/etc/fluent/plugin`` directory.

Or you can create gem package that includes ``lib/fluent/plugin/<TYPE>_<NAME>.rb`` file. *TYPE* is ``in`` for input plugins, ``out`` for output plugins and ``buf`` for buffer plugins. It's like ``lib/fluent/plugin/out_mail.rb``. The packaged gem can be distributed and installed using RubyGems.


Input plugins
------------------------------------

Extend **Fluent::Input** class and implement following methods::

    class SomeInput < Fluent::Input
      Fluent::Plugin.register_input('NAME', self)

      # `conf` is a Hash that includes configuration parameters.
      # If the configuration is invalid, raise Fluent::ConfigError.
      def configure(conf)
        @port = conf['port']
        ...
      end

      # This method is called when starting.
      # Open sockets or files here and create a Thread.
      def start
      end

      # This method is called when shutting down.
      # Shutdown the thread and Close sockets or files here.
      def shutdown
      end
    end

To submit events, use ``Fluent::Engine.emit(tag, event)`` method as following::

    tag = "myapp.access"
    time = Time.now.to_i
    record = {"message"=>"body"}
    Fluent::Engine.emit(tag, Fluent::Event.new(time, record))

RDoc of the Engine class is available from `Fluent RDoc <http://fluent.github.com/rdoc/Fluent/Engine.html>`_.


Buffered output plugins
------------------------------------

Extend **Fluent::BufferedOutput** class and implement following methods::

    class SomeOutput < Fluent::BufferedOutput
      Fluent::Plugin.register_output('NAME', self)

      # `conf` is a Hash that includes configuration parameters.
      # If the configuration is invalid, raise Fluent::ConfigError.
      def configure(conf)
        @path = conf['path']
        ...
      end

      # This method is called when starting.
      # Open sockets or files here.
      # Don't forgate call super()
      def start
        super()
      end

      # This method is called when shutting down.
      # Shutdown the thread and Close sockets or files here.
      # Don't forgate call super()
      def shutdown
        super()
      end

      # Convert event and tag to a raw string.
      def format(tag, event)
        [tag, event.time, event.record].to_json + "\n"
      end

      # Writes a buffer chunk to a files or network.
      # `chunk` is a buffer chunk that includes multiple formatted
      # events. You can use `data = chunk.read` to get all events and
      # `chunk.open {|io| }` to get IO object.
      def write(chunk)
        objs = chunk.read.split("\n").map {|raw|
          JSON.load(raw)
        }
      end
    end


Time sliced output plugins
------------------------------------

Extend **Fluent::TimeSlicedOutput** class and implement following methods::

    class SomeOutput < Fluent::TimeSlicedOutput
      Fluent::Plugin.register_output('NAME', self)

      # configure(conf), start(), shutdown() and format(tag, event) are
      # same as BufferedOutput.

      def format(tag, event)
        [tag, event.time, event.record].to_msgpack
      end

      # Writes a buffer chunk to a files or network.
      # `chunk` is a buffer chunk that includes multiple formatted
      # events. You can use `data = chunk.read` to get all events and
      # `chunk.open {|io| }` to get IO object.
      # Use `chunk.key` to get sliced time.
      def write(chunk)
        puts chunk.key  #=> e.g. "20110602" if daily
        MessagePack::Unpacker.new.feed_each(chunk.read) {|obj|
          p obj
        }
      end
    end


Non-buffered output plugins
------------------------------------

Extend **Fluent::Output** class and implement following methods::

    class SomeOutput < Fluent::Output
      def configure(conf)
      end
    
      def start
      end
    
      def shutdown
      end
    
      def emit(tag, es, chain)
        chain.next
        es.each {|event|
          $stderr.puts "OK!"
        }
      end
    end

``emit`` outputs events provided by ``es.each`` method (**es** is **EventStream**).
``chain.next`` in the emit is used in the CopyOutput. To write logs transactionally, call it appropriate point.


Buffer plugins
------------------------------------

TODO


Debug
------------------------------------

Run ``fluentd`` with ``-vv`` option to show debug messages::

    $ fluentd -vv

**stdout** and **copy** output plugins will be useful for debugging.  **stdout** output plugin dumps matched events to the console. It can be used as following::

    # You want to debug this plugin
    <source>
      type your_custom_input_plugin
    </source>

    # Dump all events to stdout
    <match *>
      type stdout
    </match>

**copy** output plugin copies matched events to multiple output plugins. You can use it with the stdout plugin::

    # Use tcp input plugin and fluent-cat command to feed events:
    #  $ echo '{"event":"message"}' | fluent-cat test.tag
    <source>
      type tcp
    </source>

    <match test.tag>
      type copy

      # Dump the matched events
      <store>
        type stdout
      </store>

      # And feed them to your plugin
      <store>
        type your_custom_output_plugin
      </store>
    </match>

