#!/usr/bin/env ruby
require 'rest-client'
require 'json'
require 'pp'  

proxyconf = RestClient::Resource.new('http://username:password@localhost:1234/')

puts "Register three clients..."
proxyconf["workers/add/app_name/service_name"].post workers: %w{10.0.0.1:9002 10.0.0.2:9200 10.0.0.10:9002}

puts "Display client hierarchy..."
puts proxyconf["workers"].get

puts "Display client list..."
puts proxyconf["workers_list"].get

puts "Get statistics..."
pp JSON.parse(proxyconf['statistics/60'].get)

puts "Unregister one client..."
proxyconf["workers/delete/app_name/service_name"].post workers: %w{10.0.0.1:9002}

puts "Unregister client from all services..."
proxyconf["workers/delete_from_all"].post workers: %w{10.0.0.10:9002}

puts "Display client hierarchy again..."
puts proxyconf["workers"].get       
