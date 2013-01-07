require_relative '../../lib/proxyconf/nginx_configuration'
require "test/unit"
require 'json'    

module ProxyConf
    class TestNginxConfiguration < Test::Unit::TestCase
	
	#def setup
	    @@context = "context123"
	    @@app = "app123"
	    @@service = "service111"
	    @@service2 = "service222"
	    @@address = "10.0.0.1"
	    @@address2 = "10.0.0.2"
	#end
	
	def test_register
	    #given 
	    conf = NginxConfiguration.new(nil)	    
	    #when 
	    conf.register(@@context, @@app, @@service, @@address) 
	    #then
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	end
	
	def test_register_two
	    #given 
	    conf = NginxConfiguration.new(nil)	    
	    #when 
	    conf.register(@@context, @@app, @@service, @@address) 
	    conf.register(@@context, @@app, @@service, @@address2) 
	    #then
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	end
 	
	def test_unregister
	    #given 
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, @@address)
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    #when 
	    ret1 = conf.unregister(@@context, @@app, @@service, @@address)
	    #then	    
	    assert(ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	end
	
	def test_unregister_one_leave_rest
	    #given 
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, @@address)
	    conf.register(@@context, @@app, @@service, @@address2)
	    conf.register(@@context, @@app, @@service2, @@address)
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    #when 
	    ret1 = conf.unregister(@@context, @@app, @@service, @@address)
	    #then
	    assert(ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	end
	
	def test_unregister_nothing
	    #given 
	    conf = NginxConfiguration.new(nil)
	    #when 
	    ret1 =conf.unregister(@@context, @@app, @@service, @@address)
	    #then	    
	    assert(!ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	end
	
	def test_unregister_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, @@address)
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, @@address2)
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	    #when 
	    ret1 = conf.unregister_from_all(@@address)
	    #then 
	    assert(ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(!conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	end
	
	def test_unregister_two_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, @@address)
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, @@address2)
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	    #when 
	    ret1 = conf.unregister_from_all(@@address)
	    ret2 = conf.unregister_from_all(@@address2)
	    #then 
	    assert(ret1)
	    assert(ret2)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(!conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address2))
	end
	
	def test_unregister_nothing_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    #when 
	    ret1 = conf.unregister_from_all(@@address)
	    #then 
	    assert(!ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, @@address))
	end
	
	def test_unregister_ip_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, "http://#{@@address}:8080")
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, "http://#{@@address2}:4000")
	    assert(conf.is_registered(@@context, @@app, @@service, "http://#{@@address}:8080"))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, "http://#{@@address2}:4000"))
	    #when 
	    ret1 = conf.unregister_ip_from_all(@@address)
	    #then 
	    assert(ret1)
	    assert(!conf.is_registered(@@context, @@app, @@service, "http://#{@@address}:8080"))
	    assert(!conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, "http://#{@@address2}:4000"))
	end
	
	def test_list_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, @@address)
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, @@address2)
	    assert(conf.is_registered(@@context, @@app, @@service, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, @@address2))
	    #when 
	    ret1 = conf.list_workers()
	    #then 
	    assert_equal(2, ret1.length)
	    assert(ret1.include?(@@address))
	    assert(ret1.include?(@@address2))
	end
	
	def test_list_ips
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, "http://#{@@address}:8080")
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, "http://#{@@address2}:4000")
	    assert(conf.is_registered(@@context, @@app, @@service, "http://#{@@address}:8080"))
	    assert(conf.is_registered(@@context, @@app, @@service2, @@address))
	    assert(conf.is_registered(@@context, @@app, @@service, "http://#{@@address2}:4000"))
	    #when 
	    ret1 = conf.list_ips()
	    #then 
	    assert_equal(2, ret1.length)
	    assert(ret1.include?(@@address))
	    assert(ret1.include?(@@address2))
	end
	
	def test_get_set_state
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@@context, @@app, @@service, "http://#{@@address}:8080")
	    conf.register(@@context, @@app, @@service2, @@address)
	    conf.register(@@context, @@app, @@service, "http://#{@@address2}:4000")
	    conf2 = NginxConfiguration.new(nil, conf.get_state)
	    assert_equal(conf.get_state, conf2.get_state)
	end 

    end
end 
