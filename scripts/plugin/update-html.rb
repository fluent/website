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
    Gem::GemRunner.new.run %w[search -r fluent-plugin]
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

gemlist = cmdout.scan(/fluent-plugin-[^\s]+/)

Plugin = Struct.new(:name, :gemname, :version, :url, :author, :summary, :downloads)

plugins = []

http = Net::HTTP.new("rubygems.org", 80)
http.start do

  gemlist.each do |gemname|
    res = http.get("/api/v1/gems/#{e gemname}.json")
    js = JSON.parse(res.body)

    url = nil
    author = nil
    summary = nil
    
    name = js['name'].sub(/^fluent-plugin-/,'')
    version = js['version']
    url = js['homepage_uri'] unless js['homepage_uri'].to_s.empty?
    author = js['authors'] unless js['authors'].to_s.empty?
    summary = js['info'] unless js['info'] == 'This rubygem does not have a description or summary.'
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

