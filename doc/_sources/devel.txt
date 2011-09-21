.. _devel:

Writing plugins
========================

.. contents::
   :backlinks: none
   :local:

Installing custom plugins
------------------------------------

To install a plugin, put a ruby script to ``/etc/fluent/plugin`` directory.

Or you can create gem package that includes ``lib/fluent/plugin/<TYPE>_<NAME>.rb`` file. *TYPE* is ``in`` for input plugins, ``out`` for output plugins and ``buf`` for buffer plugins. It's like ``lib/fluent/plugin/out_mail.rb``. The packaged gem can be distributed and installed using RubyGems. See :ref:`search_plugin`.


Input plugins
------------------------------------

Extend **Fluent::Input** class and implement following methods::

    class SomeInput < Fluent::Input
      # Register plugin first. NAME is the name of this plugin
      # which is used in the configuration file.
      Fluent::Plugin.register_input('NAME', self)

      # This method is called before starting.
      # 'conf' is a Hash that includes configuration parameters.
      # If the configuration is invalid, raise Fluent::ConfigError.
      def configure(conf)
        @port = conf['port']
        ...
      end

      # This method is called when starting.
      # Open sockets or files and create a thread here.
      def start
        ...
      end

      # This method is called when shutting down.
      # Shutdown the thread and close sockets or files here.
      def shutdown
        ...
      end
    end

To submit events, use ``Fluent::Engine.emit(tag, event)`` method, where ``tag`` is the String and ``event`` is a ``Fluent::Event`` object::

    tag = "myapp.access"
    time = Time.now.to_i
    record = {"message"=>"body"}
    Fluent::Engine.emit(tag, Fluent::Event.new(time, record))

RDoc of the Engine class is available from `Fluent RDoc <http://fluent.github.com/rdoc/Fluent/Engine.html>`_.


Buffered output plugins
------------------------------------

Extend **Fluent::BufferedOutput** class and implement following methods::

    class SomeOutput < Fluent::BufferedOutput
      # Register plugin first. NAME is the name of this plugin
      # which is used in the configuration file.
      Fluent::Plugin.register_output('NAME', self)

      # This method is called before starting.
      # 'conf' is a Hash that includes configuration parameters.
      # If the configuration is invalid, raise Fluent::ConfigError.
      def configure(conf)
        super
        @path = conf['path']
        ...
      end

      # This method is called when starting.
      # Open sockets or files here.
      # Don't forget to call super
      def start
        super
        ...
      end

      # This method is called when shutting down.
      # Shutdown the thread and Close sockets or files here.
      # Don't forget to call super
      def shutdown
        super
        ...
      end

      # This method is called when an event is reached.
      # Convert event and tag to a raw string.
      def format(tag, event)
        [tag, event.time, event.record].to_json + "\n"
      end

      # This method is called every flush interval. rite the buffer chunk
      # to files or databases here.
      # 'chunk' is a buffer chunk that includes multiple formatted
      # events. You can use 'data = chunk.read' to get all events and
      # 'chunk.open {|io| ... }' to get IO object.
      def write(chunk)
        objs = chunk.read.split("\n").map {|raw|
          JSON.load(raw)
        }
      end
    end


Time sliced output plugins
------------------------------------

Time sliced output plugins are extended version of buffered output plugin. One of the examples of time sliced output is ``out_file`` plugin.

Note that it uses file buffer by default. Thus ``buffer_path`` option is required.

To implement time sliced output plugin, Extend **Fluent::TimeSlicedOutput** class and implement following methods::

    class SomeOutput < Fluent::TimeSlicedOutput
      # configure(conf), start(), shutdown() and format(tag, event) are
      # same as BufferedOutput.
      ...

      # You can use 'chunk.key' to get sliced time. Format of the 'chunk.key'
      # can be configured by 'time_format' option. Default format is %Y%m%d.
      def write(chunk)
        day = chunk.key
        ...
      end
    end


Non-buffered output plugins
------------------------------------

Extend **Fluent::Output** class and implement following methods::

    class SomeOutput < Fluent::Output
      # Register plugin first. NAME is the name of this plugin
      # which is used in the configuration file.
      Fluent::Plugin.register_output('NAME', self)

      # This method is called before starting.
      def configure(conf)
        ...
      end
    
      # This method is called when starting.
      def start
        ...
      end
    
      # This method is called when shutting down.
      def shutdown
        ...
      end
    
      # This method is called when an event is reached.
      # 'es' is a Fluent::EventStream object that includes multiple events.
      # You can use 'es.each {|event| ... }' to retrieve events.
      # 'chain' is an object that manages transaction. Call 'chain.next' at
      # appropriate point and rollback if it raises exception.
      def emit(tag, es, chain)
        chain.next
        es.each {|event|
          $stderr.puts "OK!"
        }
      end
    end


Buffer plugins
------------------------------------

TODO


Debugging plugins
------------------------------------

Run ``fluentd`` with ``-vv`` option to show debug messages::

    $ fluentd -vv

**stdout** and **copy** output plugins is useful for debugging. **stdout** output plugin dumps matched events to the console. It can be used as following::

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

