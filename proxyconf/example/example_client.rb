#!/usr/bin/env ruby
require 'rest-client'  
require 'json'
require 'pp'
              
       
proxyconf = RestClient::Resource.new('http://127.0.0.1:1234/')

puts "Register two clients..."
proxyconf["workers/add/app_name/service_name"].post workers: %w{10.42.1.1:9002 10.42.1.8:9200}

puts "Display client list..."
puts proxyconf["workers"].get

puts "Get statistics..."
pp JSON.parse(proxyconf['statistics/60'].get)

puts "Unregister one client..."
proxyconf["workers/delete/app_name/service_name"].post workers: %w{10.42.0.1:9002}

puts "Display client list again..."
puts proxyconf["workers"].get