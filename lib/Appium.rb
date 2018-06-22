require 'socket'
require 'timeout'

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
  command << " --udid #{options[:udid]}" if options.key?(:udid)
  command << " --automation-name #{options[:automationName]}" if options.key?(:automationName)
  command << " --webkit-debug-proxy-port #{options[:webkitPort]}" if options.key?(:webkitPort)
  command << " --tmp /tmp/#{options[:tmp]}" if options.key?(:tmp)
  command << " --chromedriver-port #{options[:cp]}" if options.key?(:cp)
  command << " --relaxed-security"
  Dir.chdir('.') {
    Thread.new do
      system(command)
    end
    puts 'Waiting for Appium to start up...'
    sleep 5
  }
end

def launch_hub_and_nodes(ip, hubIp, hubPort, nodeDir)
  
  if Gem::Platform.local.os == 'darwin'
    ios_devices = JSON.parse(get_ios_devices)
    connect_ios_devices(ip, hubIp, hubPort, nodeDir, ios_devices)
  end

  android_devices = JSON.parse(get_android_devices)
  connect_android_devices(ip, hubIp, hubPort, nodeDir, android_devices)
end

def connect_android_devices(ip, hubIp, hubPort, nodeDir, devices)
  devices.size.times do |index|
    config_name = "#{devices[index]["udid"]}.json"
    node_config = nodeDir + '/node_configs/' +"#{config_name}"

    unless File.exist?(node_config)

      new_index = index
      port = 4000 + new_index
      bp = 2250 + new_index
      cp = 6000 + new_index
      result = false

      while result == false
        if android_ports_are_open(port, bp, cp)
          result = true
        else
          new_index += 1
          port = 4000 + new_index
          bp = 2250 + new_index
          cp = 6000 + new_index
        end
      end

      sdkv = get_device_osv(devices[index]['udid']).strip.to_i
      os_ver = get_android_version(devices[index]['udid']).strip
      build = get_device_build(devices[index]['udid']).strip
      model = get_device_model(devices[index]['udid']).strip
      brand = get_device_brand(devices[index]['udid']).strip
      number = get_device_phone_number(devices[index]['udid'])
      generate_node_config(nodeDir, config_name, devices[index]["udid"], port, ip, hubIp, hubPort, 'android', 'chrome', os_ver, build, model, brand, number)
      appium_server_start(config: node_config, port: port, bp: bp, udid: devices[index]["udid"], log: "appium-#{devices[index]["udid"]}.log", tmp: devices[index]["udid"], cp: cp, config_dir: nodeDir)
    end
  end
end

def connect_ios_devices(ip, hubIp, hubPort, nodeDir, devices)
  devices.size.times do |index|
    udid = devices[index]["udid"]
    config_name = "#{udid}.json"
    node_config = nodeDir + '/node_configs/' +"#{config_name}"

    unless File.exist?(node_config)
      new_index = index
      port = 4000 + new_index
      webkitPort = 27753 + new_index
      result = false

      while result == false
        if ios_ports_are_open(port, webkitPort)
          result = true
        else
          new_index += 1
          port = 4000 + new_index
          webkitPort = 27753 + new_index
        end
      end
      config_name = "#{udid}.json"
      details = get_ios_details(udid)
      next if details.nil?
      os_ver = details["os_ver"]
      build = details["build"]
      model = details["model"]
      number = details["number"]
      generate_node_config(nodeDir, config_name, udid, port, ip, hubIp, hubPort, 'IOS', 'safari', os_ver, build, model, 'apple', number)
      node_config = nodeDir + '/node_configs/' +"#{config_name}"
      appium_server_start config: node_config, port: port, udid: udid, log: "appium-#{devices[index]["udid"]}.log", tmp: devices[index]["udid"], webkitPort: webkitPort, config_dir: nodeDir
    end
  end
end

def ios_ports_are_open(port, wb)
  is_port_open?(port) &&
    is_port_open?(wb)
end

def android_ports_are_open(port, bp, cp)
  is_port_open?(port) &&
    is_port_open?(bp) &&
    is_port_open?(cp)
end

def is_port_open?(port)
  local_ip = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '172.17.0.1'`
  begin
    Timeout.timeout(2) do
      begin
        TCPSocket.new(local_ip, port)
        return false
      rescue Errno::ENETUNREACH, Errno::ECONNREFUSED
        retry
      end
    end
  rescue Timeout::Error
    return true
  end
end
