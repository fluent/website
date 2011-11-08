.. _example:

Examples
========================

.. contents::
   :backlinks: none
   :local:


..Reliable log forwarding (active-backup)
..-----------------------------------------------------
..
..This example assumes following network::
..
..                       active log server
..                       +--------+
..                    +--> fluent | 192.168.0.1
..    front server    |  +--------+
..    +--------+      |
..    | fluent -------+
..    +--------+      |  backup log server
..                    |  +--------+
..                    +--> fluent | 192.168.0.2
..                       +--------+
..
..On the front servers, use following configuration::
..
..    <match PATTERN>
..      type tcp
..      host 192.168.0.1
..      port 24224
..    
..      # use file buffer to buffer events on disks.
..      buffer_type file
..      buffer_path /var/log/fluent/buffer/myforward
..    
..      # use longer flush_interval to reduce CPU usage.
..      # this is trade-off of latency.
..      flush_interval 60s
..    
..      # use secondary host
..      <secondary>
..        host 192.168.0.2
..        port 24224
..      </secondary>
..    </match>
..
..On the log servers, add ``tcp`` input not exists::
..
..    <source>
..      type tcp
..      port 24224
..    </source>
..
..Reliable log forwarding (active-active)
..-----------------------------------------------------
..
..You can use active-active formation by using following configuration on the front servers::
..
..    <match PATTERN>
..      # use 'roundrobin' output plugin
..      type roundrobin
..    
..      <store>
..        type tcp
..        host 192.168.0.1
..        port 24224
..    
..        buffer_type file
..        buffer_path /var/log/fluent/buffer/myforward-1
..        flush_interval 60s
..    
..        <secondary>
..          host 192.168.0.2
..          port 24224
..        </secondary>
..      </store>
..
..      <store>
..        type tcp
..        host 192.168.0.2
..        port 24224
..    
..        buffer_type file
..        buffer_path /var/log/fluent/buffer/myforward-2
..        flush_interval 60s
..    
..        <secondary>
..          host 192.168.0.1
..          port 24224
..        </secondary>
..      </store>
..    </match>

