require 'socket'
require 'timeout'
require 'pry'

platform = get_platform()
if platform == :windows
  require 'Win32API'
end

def shortname long_name
  max_path = 1024
  short_name = " " * max_path
  lfn_size = Win32API.new("kernel32", "GetShortPathName", ['P','P','L'],'L').call(long_name, short_name, max_path)
  return short_name[0..lfn_size-1]
end

def appium_server_start(**options)
  command = 'appium'
  command << " --nodeconfig #{options[:config]}" if options.key?(:config)
  command << " -p #{options[:port]}" if options.key?(:port)
  command << " -bp #{options[:bp]}" if options.key?(:bp)

  Dir.chdir('.') {
    Thread.new do
      system(command)
    end

    puts 'Waiting for Appium to start up...'
    sleep 5
  }
end



def launch_hub_and_nodes(ip, hubIp, nodeDir)

  devices = JSON.parse(get_android_devices)

  devices.size.times do |index|
    config_name = "#{devices[index]["udid"]}.json"
    node_config = nodeDir + '/node_configs/' +"#{config_name}"

    unless File.exist?(node_config)

      new_index = index
      port = 4000 + new_index
      result = false

      while result == false
        if is_port_open?('localhost', port)
          result = true
        else
          new_index += 1
          port = 4000 + new_index
        end
      end

      bp = 2250 + new_index
      sdp = 5000 + new_index
      cp = 6000 + new_index
      sdkv = get_device_osv(devices[index]['udid']).strip.to_i
      os_ver = get_android_version(devices[index]['udid']).strip
      build = get_device_build(devices[index]['udid']).strip
      model = get_device_model(devices[index]['udid']).strip
      brand = get_device_brand(devices[index]['udid']).strip
      generate_node_config(nodeDir, config_name, devices[index]["udid"], port, ip, hubIp, 'android', 'chrome', os_ver, build, model, brand)
      appium_server_start(config: node_config, port: port, bp: bp, udid: devices[index]["udid"], log: "appium-#{devices[index]["udid"]}.log", tmp: devices[index]["udid"], cp: cp, config_dir: nodeDir)
    end
  end
end

def is_port_open?(ip, port)
  begin
    Timeout.timeout(2) do
      begin
        TCPSocket.new(ip, port)
        return false
      rescue Errno::ENETUNREACH, Errno::ECONNREFUSED
        retry
      end
    end
  rescue Timeout::Error
    return true
  end
end
