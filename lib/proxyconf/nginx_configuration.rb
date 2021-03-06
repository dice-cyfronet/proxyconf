require_relative './config_generation'
require 'monitor'
require 'net/dns'
require 'set'
require 'net/dns/resolver'

module ProxyConf
  class NginxConfiguration

  @@address_regex = /(.*:\/\/)?([^:\/]*)([:\/].*)?/

  attr_reader :dns_map, :config

  public
    # Constructor
    # @param [Hash] config Data from configuration file
    def initialize(config, state = nil )
      @config = config
      set_state(state)
    end

    def get_state()
      { 'contexts' => @contexts, 'dns_map' => @dns_map}
    end

    def set_state(state = nil)
      @contexts = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = [] } } }
      @dns_map = {}
      if state then
        state['contexts'].each{ |context, v1|
          v1.each {|application, v2|
            v2.each{|service, workers|
              @contexts[context][application][service] = workers
            }
          }
        }
        @dns_map = state['dns_map']
      end
      @dns_map.extend(MonitorMixin)
    end

    def is_registered(context_id, application_id, service_name, addr)
      @contexts[context_id][application_id][service_name].include? addr
    end

    # Registers worker
    #
    # If DNS name is given, all IP addresses are registered. If worker is already registered does nothing.
    # @param [String] context_id Context id
    # @param [String] application_id Application id
    # @param [String] service_name Service name
    # @param [String] addr Service address

    def register(context_id, application_id, service_name, addr)
      p "checking #{context_id} #{application_id} #{service_name}"
      unless @contexts[context_id][application_id][service_name].include? addr
        unless addr =~ /^\d+\.\d+\.\d+\.\d+(:\d+)?$/
          addr_parts = /^([^:]*)(:\d+)?/.match addr
          port = if addr_parts[2] then addr_parts[2] else ":80" end
          Net::DNS::Resolver.start(addr_parts[1], Net::DNS::A).each_address do |ip|
            @dns_map.synchronize do
              @dns_map[ip.to_s+port] = addr
            end
          end
        end
        @contexts[context_id][application_id][service_name] << addr

      end
    end

    # Unregisters worker
    #
    # If worker is not registered does nothing.
    # @param [String] context_id Context id
    # @param [String] application_id Application id
    # @param [String] service_name Service name
    # @param [String] addr Service address
    def unregister(context_id, application_id, service_name, addr)
      if @contexts.has_key? context_id and @contexts[context_id].has_key? application_id and @contexts[context_id][application_id].has_key? service_name then
        ret = @contexts[context_id][application_id][service_name].delete addr
        @dns_map.synchronize do
           @dns_map.delete_if { |k,v| v == addr }
        end
        # data structures cleanup
	@contexts[context_id][application_id].delete service_name if @contexts[context_id][application_id][service_name].size == 0
        @contexts[context_id].delete application_id if @contexts[context_id][application_id].size == 0
        @contexts.delete context_id if @contexts[context_id].size == 0
      end
      ret
    end

    # Unregisters address from all services
    #
    # @param [String] addr Service address
    def unregister_from_all(addr)
	matches = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = Set.new } }
	ret = false
	@contexts.each_pair do |context_id, applications|
	    applications.each_pair do |application_id, services|
		services.each_pair do |service_id, addresses|
		    if addresses.include?(addr) && !matches[context_id][application_id].include?(service_id) then
			matches[context_id][application_id].add(service_id)
		    end
		end
	    end
	end
	matches.each_pair do |context_id, applications|
	    applications.each_pair do |application_id, services|
		services.each do |service_id|
		   ret |= unregister(context_id, application_id, service_id, addr)
		end
	    end
	end
	ret
    end

    # Unregisters ip from all services
    #
    # @param [String] addr Service address
    def unregister_ip_from_all(ip)
	matches = []
	ret = false
	@contexts.each_pair do |context_id, applications|
	    applications.each_pair do |application_id, services|
		services.each_pair do |service_id, addresses|
		    addresses.each do |address|
			if @@address_regex.match(address).captures[1] == ip
			    matches << [context_id, application_id, service_id, address]
			end
		    end
		end
	    end
	end
	matches.each do |match|
	    ret |= unregister(match[0], match[1], match[2], match[3])
	end
	ret
    end

    # Returns hash of applications and their workers
    # @return [Hash]
    def list
      @contexts
    end

    # Returns a set of all registered ips
    # @return [Set]
    def list_ips
       set = Set.new
       @contexts.each_pair do |context_id, applications|
	    applications.each_pair do |application_id, services|
		services.each_pair do |service_id, addresses|
		    addresses.each do |address|
			set << @@address_regex.match(address).captures[1]
		    end
		end
	    end
	end
	set.to_a()
    end

    # Returns a set of all registered workers
    # @return [Set]
    def list_workers
       set = Set.new
       @contexts.each_pair do |context_id, applications|
	    applications.each_pair do |application_id, services|
		services.each_pair do |service_id, addresses|
		    addresses.each do |address|
			set << address
		    end
		end
	    end
	end
	set.to_a()
    end

  private

    # Generate nginx proxy config
    # @return Two element array: upstream configuration and proxy configuration.
    def configuration
	ConfigGeneration.new(@contexts, @config["proxy_timeout"], @config["proxy_send_timeout"]).generate
    end

  public
    # Save nginx proxy config to disk and reload server configuration
    def configure
      upstream_config, proxy_config = configuration
      begin
        File.open(@config["upstream_config"],"w") { |file| file.write upstream_config }
        File.open(@config["proxy_config"],"w") { |file| file.write proxy_config }

        File.open(@config["pid_file"]) do |file|
         pid = file.read.to_i
         Process.kill :SIGHUP, pid
        end
      rescue Errno::EACCES
        $stderr << "Error: Cannot write to config files\n"
        raise
      rescue Errno::ESRCH
        $stderr << "Warning: Nginx is dead - continuing\n"
      end
    end
  end
end