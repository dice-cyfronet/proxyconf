require "sinatra/base" 
require "sinatra/sugar"               
require 'json'    
module ProxyConf     
  class RESTInterface < Sinatra::Base
    # return JSON list of registered workers (as Hash(Key = application_id) of Hash(Key = service_name) of Array (of worker host:port))
    get '/workers' do
      content_type :json
      settings.proxyconf.list.to_json
    end
    
    # Registers given workers
    post '/workers/add/:application_id/:service_name' do      
      params[:workers].each do |worker|
        settings.proxyconf.register(params[:application_id], params[:service_name], worker)
      end
      settings.proxyconf.configure
      
      "OK"
    end
    
    # Unregisters given workers
    post '/workers/delete/:application_id/:service_name' do            
      success = false
      params[:workers].each do |worker|
        success |= settings.proxyconf.unregister(params[:application_id], params[:service_name], worker)
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
  end
end