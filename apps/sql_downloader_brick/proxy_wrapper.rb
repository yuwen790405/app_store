require 'json'

definition = JSON.parse(File.read('/mnt/definition.json'))
definition[:executable] = 'wrapper.rb'
File.open('/mnt/definition.json','w') do |f|
  f.write(definition.to_json)
end

system("/usr/bin/java -Xmx2048m -DsocksProxyHost=#{ENV['ENV_PROXY_HOST']} -cp '/usr/share/java/executor-wrapper/*' com.gooddata.executor.ExecutorWrapper -f /mnt/definition.json")