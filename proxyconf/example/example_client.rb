#!/usr/bin/env ruby
require 'rest-client'
require 'json'
require 'pp'  

proxyconf = RestClient::Resource.new('http://username:password@localhost:1234/')

puts "Register four clients..."
proxyconf["workers/add/context_name/app_name/service_name"].post workers: %w{10.0.0.1:9002 10.0.0.2:9200 10.0.0.10:9002 10.0.0.7:1233}

puts "Display client hierarchy..."
puts proxyconf["workers"].get

puts "Display client list..."
puts proxyconf["worker_list"].get

puts "Display registered ip list..."
puts proxyconf["ip_list"].get

puts "Get statistics..."
pp JSON.parse(proxyconf['statistics/60'].get)

puts "Unregister one client..."
proxyconf["workers/delete/context_name/app_name/service_name"].post workers: %w{10.42.0.1:9002}

puts "Unregister clients from all services..."
proxyconf["workers/delete_all"].post workers: %w{10.0.0.10:9002}

puts "Unregister ips from all services..."
proxyconf["workers/delete_all"].post ips: %w{10.0.0.7}

puts "Display client hierarchy again..."
puts proxyconf["workers"].get       
