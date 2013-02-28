require_relative '../../lib/proxyconf/config_generation'
require "test/unit"
require "open-uri"

module ProxyConf
    class TestStringGeneration < Test::Unit::TestCase

	def test_generation
	    #given
	    context = "context123"
	    app = "app123"
	    service = "service111"
	    service2 = "service222"
	    address = "www.google.pl"
	    address2 = "www.google2.pl"
	    proxy_timeout = 10
	    proxy_send_timeout = 10

	    contexts = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = [] } } }
	    contexts[context][app][service] << address;
	    contexts[context][app][service2] << address;
	    contexts[context][app][service] << address2;

	    generation = ConfigGeneration.new(contexts, proxy_timeout, proxy_send_timeout)

	    #then
	    upstream_config, proxy_config = generation.generate

	    assert(upstream_config.gsub(/[\s\n]/, "").include?("
	    upstream ctx.#{context}.app.#{app}.service.#{service} { 
		server #{address};  
		server #{address2}; 
	    }
	    ".gsub(/[\s\n]/, "")));

	    assert(upstream_config.gsub(/[\s\n]/, "").include?("
	    upstream ctx.#{context}.app.#{app}.service.#{service2} { 
		server #{address}; 
	    }
	    ".gsub(/[\s\n]/, "")));

	    assert(proxy_config.gsub(/[\s\n]/, "").include?"
	    location \/#{context}\/#{app}\/#{service}\/ {
		proxy_read_timeout #{proxy_timeout};
	        proxy_send_timeout #{proxy_send_timeout};
		proxy_pass http:\/\/ctx.#{context}.app.#{app}.service.#{service}\/;
	        proxy_set_header X-Path-Prefix \"/#{context}/#{app}/#{service}\";
	        proxy_set_header X-Server-Address http:\/\/$server_addr:$server_port;
	    }   
	    ".gsub(/[\s\n]/, ""));

	    assert(proxy_config.gsub(/[\s\n]/, "").include?"
	    location \/#{context}\/#{app}\/#{service2}\/ {
		proxy_read_timeout #{proxy_timeout};
	        proxy_send_timeout #{proxy_send_timeout};
		proxy_pass http:\/\/ctx.#{context}.app.#{app}.service.#{service2}\/;
	        proxy_set_header X-Path-Prefix \"/#{context}/#{app}/#{service2}\";  
	        proxy_set_header X-Server-Address http:\/\/$server_addr:$server_port;
	    }".gsub(/[\s\n]/, ""));
  end

  def test_generation_encoding_engaged
    #given
    context = "context 123"
    app = "app 123"
    service = "service 111"
    service2 = "service 222"
    address = "www.google.pl"
    address2 = "www.google2.pl"
    proxy_timeout = 10
    proxy_send_timeout = 10

    contexts = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = [] } } }
    contexts[context][app][service] << address;
    contexts[context][app][service2] << address;
    contexts[context][app][service] << address2;

    generation = ConfigGeneration.new(contexts, proxy_timeout, proxy_send_timeout)

    #then
    upstream_config, proxy_config = generation.generate

    assert(upstream_config.gsub(/[\s\n]/, "").include?("
	    upstream ctx.#{URI::encode(context)}.app.#{URI::encode(app)}.service.#{URI::encode(service)} {
		server #{address};
		server #{address2};
	    }
	    ".gsub(/[\s\n]/, "")));

    assert(upstream_config.gsub(/[\s\n]/, "").include?("
	    upstream ctx.#{URI::encode(context)}.app.#{URI::encode(app)}.service.#{URI::encode(service2)} {
		server #{address};
	    }
	    ".gsub(/[\s\n]/, "")));

    assert(proxy_config.gsub(/[\s\n]/, "").include?"
	    location \/#{URI::encode(context)}\/#{URI::encode(app)}\/#{URI::encode(service)}\/ {
		proxy_read_timeout #{proxy_timeout};
	        proxy_send_timeout #{proxy_send_timeout};
		proxy_pass http:\/\/ctx.#{URI::encode(context)}.app.#{URI::encode(app)}.service.#{URI::encode(service)}\/;
	        proxy_set_header X-Path-Prefix \"/#{URI::encode(context)}/#{URI::encode(app)}/#{URI::encode(service)}\";
	        proxy_set_header X-Server-Address http:\/\/$server_addr:$server_port;
	    }
	    ".gsub(/[\s\n]/, ""));

    assert(proxy_config.gsub(/[\s\n]/, "").include?"
	    location \/#{URI::encode(context)}\/#{URI::encode(app)}\/#{URI::encode(service2)}\/ {
		proxy_read_timeout #{proxy_timeout};
	        proxy_send_timeout #{proxy_send_timeout};
		proxy_pass http:\/\/ctx.#{URI::encode(context)}.app.#{URI::encode(app)}.service.#{URI::encode(service2)}\/;
	        proxy_set_header X-Path-Prefix \"/#{URI::encode(context)}/#{URI::encode(app)}/#{URI::encode(service2)}\";
	        proxy_set_header X-Server-Address http:\/\/$server_addr:$server_port;
	    }".gsub(/[\s\n]/, ""));
  end
	
    end
end 
