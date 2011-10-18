require 'rubygems'
require 'rubygems/gem_runner'
require 'rubygems/exceptions'
require 'json'
require 'net/http'
require 'cgi'
require 'erb'

def e(s)
  CGI.escape(s.to_s)
end

def h(s)
  CGI.escapeHTML(s.to_s)
end

tmpl = File.dirname(__FILE__)+"/template.erb"
out = File.dirname(__FILE__)+"/index.html"

rpipe, wpipe = IO.pipe

pid = Process.fork do
  rpipe.close
  $stdout.reopen wpipe
  begin
    Gem::GemRunner.new.run %w[search -rd fluent-plugin]
  rescue Gem::SystemExitException => e
    exit e.exit_code
  end
  exit 0
end
wpipe.close
cmdout = rpipe.read
Process.waitpid2(pid)
ecode = $?.to_i
if ecode != 0
  exit ecode
end

splits = cmdout.split(/^(\S+)\s+\(([^\)]+)\)\n/)
splits.shift  # remove first ""

Plugin = Struct.new(:name, :gemname, :version, :url, :author, :summary, :downloads)

plugins = []

http = Net::HTTP.new("rubygems.org", 80)
http.start do

  until splits.empty?
    gemname = splits.shift
    version = splits.shift
    meta, summary = splits.shift.split("\n\n")
    name = gemname.sub(/^fluent-plugin-/,'')

    url = nil
    author = nil

    meta.each_line {|line|
      case line
      when /Author: (.*)$/
        author = $~[1]
      when /Homepage: (.*)$/
        url = $~[1]
      end
    }

    summary = summary.each_line.map {|line|
      summary.strip
    }.join("\n")

    res = http.get("/api/v1/gems/#{e gemname}.json")
    js = JSON.parse(res.body)

    downloads = js['downloads']

    plugins << Plugin.new(name, gemname, version, url, author, summary, downloads)
  end

end

plugins = plugins.sort_by {|pl| -pl.downloads }

erb = ERB.new(File.read(tmpl))
result = erb.result(binding)

File.open(out, "w") {|f|
  f.write result
}

