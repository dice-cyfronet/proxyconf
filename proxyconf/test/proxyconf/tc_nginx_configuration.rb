require_relative '../../lib/proxyconf/nginx_configuration'
require "test/unit"

module ProxyConf
    class TestNginxConfiguration < Test::Unit::TestCase
	
	def setup
	    @context = "context123"
	    @app = "app123"
	    @service = "service111"
	    @service2 = "service222"
	    @address = "www.google.pl"
	    @address2 = "www.google2.pl"
	end
	
	def test_register
	    #given 
	    conf = NginxConfiguration.new(nil)	    
	    #when 
	    conf.register(@context, @app, @service, @address) 
	    #then
	    assert(conf.is_registered(@context, @app, @service, @address))
	end
	
	def test_register_two
	    #given 
	    conf = NginxConfiguration.new(nil)	    
	    #when 
	    conf.register(@context, @app, @service, @address) 
	    conf.register(@context, @app, @service, @address2) 
	    #then
	    assert(conf.is_registered(@context, @app, @service, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	end
 	
	def test_unregister
	    #given 
	    conf = NginxConfiguration.new(nil)
	    conf.register(@context, @app, @service, @address)
	    assert(conf.is_registered(@context, @app, @service, @address))
	    #when 
	    ret1 = conf.unregister(@context, @app, @service, @address)
	    #then	    
	    assert(ret1)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	end
	
	def test_unregister_one_leave_rest
	    #given 
	    conf = NginxConfiguration.new(nil)
	    conf.register(@context, @app, @service, @address)
	    conf.register(@context, @app, @service, @address2)
	    conf.register(@context, @app, @service2, @address)
	    assert(conf.is_registered(@context, @app, @service, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	    assert(conf.is_registered(@context, @app, @service2, @address))
	    #when 
	    ret1 = conf.unregister(@context, @app, @service, @address)
	    #then
	    assert(ret1)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	    assert(conf.is_registered(@context, @app, @service2, @address))
	end
	
	def test_unregister_nothing
	    #given 
	    conf = NginxConfiguration.new(nil)
	    #when 
	    ret1 =conf.unregister(@context, @app, @service, @address)
	    #then	    
	    assert(!ret1)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	end
	
	def test_unregister_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@context, @app, @service, @address)
	    conf.register(@context, @app, @service2, @address)
	    conf.register(@context, @app, @service, @address2)
	    assert(conf.is_registered(@context, @app, @service, @address))
	    assert(conf.is_registered(@context, @app, @service2, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	    #when 
	    ret1 = conf.unregister_from_all(@address)
	    #then 
	    assert(ret1)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	    assert(!conf.is_registered(@context, @app, @service2, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	end
	
	def test_unregister_two_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    conf.register(@context, @app, @service, @address)
	    conf.register(@context, @app, @service2, @address)
	    conf.register(@context, @app, @service, @address2)
	    assert(conf.is_registered(@context, @app, @service, @address))
	    assert(conf.is_registered(@context, @app, @service2, @address))
	    assert(conf.is_registered(@context, @app, @service, @address2))
	    #when 
	    ret1 = conf.unregister_from_all(@address)
	    ret2 = conf.unregister_from_all(@address2)
	    #then 
	    assert(ret1)
	    assert(ret2)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	    assert(!conf.is_registered(@context, @app, @service2, @address))
	    assert(!conf.is_registered(@context, @app, @service, @address2))
	end
	
	def test_unregister_nothing_from_all
	    #given
	    conf = NginxConfiguration.new(nil)
	    #when 
	    ret1 = conf.unregister_from_all(@address)
	    #then 
	    assert(!ret1)
	    assert(!conf.is_registered(@context, @app, @service, @address))
	end

    end
end 
