require 'net/http'
require 'net/https'
require 'uri'
require 'yaml'
require 'rubygems'
require 'json' # gem install json_pure
require 'serialport' # gem install ruby-serialport 
require 'ap'  # awesome print: gem install awesome_print

def load_settings_from_yaml
  configfile ="settings.yml"
  if File.exists?(configfile) then
    settings = YAML.load_file(configfile)
    if settings.class == Hash
      return settings
    end
  end
  return nil   
end

def fetch_url_content(fetch_url)
  urlcontent = ''
  fetch_uri = URI.parse(fetch_url)
  if(fetch_uri.scheme.nil?)
    raise StandardError, "Fetch URL Content:  Invalid URL: #{fetch_url}"
  elsif(fetch_uri.scheme == 'http' or fetch_uri.scheme == 'https')  
    # TODO: need to set If-Modified-Since
    http = Net::HTTP.new(fetch_uri.host, fetch_uri.port)
    http.use_ssl = (fetch_uri.scheme == 'https') 
    http.read_timeout = 300
    response = fetch_uri.query.nil? ? http.get(fetch_uri.path) : http.get(fetch_uri.path + "?" + fetch_uri.query)
    case response
    # TODO: handle redirection?
    when Net::HTTPSuccess
      urlcontent = response.body
    else
      raise StandardError, "Fetch URL Content:  Fetch from #{fetch_url} failed: #{response.code}/#{response.message}"          
    end    
  else # unsupported URL scheme
    raise StandardError, "Fetch URL Content:  Unsupported scheme #{feed_url}"          
  end
  return urlcontent
end

# load my settings from yaml
if(!@config_settings = load_settings_from_yaml)
  puts "Unable to read settings from settings.yml!"
  exit(0)
end

if(!@config_settings['apikey'] or !@config_settings['child'])
  puts "Missing settings from settings.yml!"
  exit(0)
end

@url = "https://go.trixietracker.com:443/api/sleep_probability?apikey=#{@config_settings['apikey']}&child=#{@config_settings['child']}"
sleep_json = fetch_url_content(@url)
ap sleep_json
sleep_data = JSON.parse(sleep_json)
ap sleep_data

sp = SerialPort.new "/dev/tty.usbmodem5d11", 9600
if(sleep_data["current"] == 'asleep')
  sp.putc(0)
else
  sp.putc(1)
end
sp.putc((sleep_data['probability']*100).to_i)
for i in 0..5 do
  sp.putc((sleep_data['next_hour'][i]*100).to_i)
end

sp.close