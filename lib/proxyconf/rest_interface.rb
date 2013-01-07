require "sinatra/base" 
require "sinatra/sugar"               
require 'json'    
require 'yaml'    
module ProxyConf     
  class RESTInterface < Sinatra::Base      
    
    use Rack::Auth::Basic, "Restricted Area" do |usr, pass|            
      [usr, pass] == [username, password]
    end
    
    # return JSON list of registered workers (as Hash(Key = application_id) of Hash(Key = service_name) of Array (of worker host:port))
    get '/workers' do
      content_type :json
      settings.proxyconf.list.to_json
    end
    
    # return JSON list of registered workers (as Array (of worker host:port))
    get '/worker_list' do
      content_type :json
      settings.proxyconf.list_workers.to_json
    end
    
    # return JSON list of registered ips (as Array (of ip))
    get '/ip_list' do
      content_type :json
      settings.proxyconf.list_ips.to_json
    end
   
    # Registers given workers
    post '/workers/add/:context_id/:application_id/:service_name' do      
      params[:workers].each do |worker|
        settings.proxyconf.register(params[:context_id], params[:application_id], params[:service_name], worker)
      end
      settings.proxyconf.configure
      "OK"
    end
    
    # Unregisters given workers
    post '/workers/delete/:context_id/:application_id/:service_name' do            
      success = false
      params[:workers].each do |worker|
        success |= settings.proxyconf.unregister(params[:context_id], params[:application_id], params[:service_name], worker)
      end
      settings.proxyconf.configure if success
      "OK"
    end     
    
     # Unregisters given workers from all services
    post '/workers/delete_all' do            
      success = false
      if params[:workers]
	params[:workers].each do |worker|
	    success |= settings.proxyconf.unregister_from_all(worker)
	end
      elsif params[:ips]
	params[:ips].each do |ip|
	    success |= settings.proxyconf.unregister_ip_from_all(ip)
	end
      end 
      settings.proxyconf.configure if success
      "OK"
    end     

    # Returns statistics for all workers
    get '/statistics/:duration' do  
      content_type :json 
      ret = {} 
      settings.proxyconf.list.each_pair do |app, services|
        ret[app] = {}
        services.each_pair do |service, workers|
          ret[app][service] = {}
          workers.each do |worker_addr|
            ret[app][service][worker_addr] = settings.log_reader.get_stats_for_worker(worker_addr,params[:duration].to_i)
          end
        end
      end
      ret.to_json
    end
    
    # Dumps current state to file 
    post '/dump' do      
      File.open(settings.proxyconf.config["dump_file"], "w"){|f| YAML.dump(settings.proxyconf.get_state, f)}
      "OK"
    end
    
    # Restores saved state from file
    post '/restore' do      
      begin      
        saved_state = YAML::load_file settings.proxyconf.config["dump_file"]
        settings.proxyconf.set_state(saved_state)
        "OK"
      rescue Exception => e
        "ERROR: #{e}" 
      end  
    end
    
  end
end