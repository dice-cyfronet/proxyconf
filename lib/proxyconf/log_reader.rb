require 'monitor'                 
require 'file/tail'
require_relative 'core_ext/array'

module ProxyConf
  class LogReader

    attr_reader :path, :diff_time, :log_entries
    
    # Constructor
    # @param [String] path Path to log file
    # @param [Numeric] diff_time Buffer size for statistics in seconds
    # @param [Hash] dns_map Keys are IP addresses and values are domain names 
    def initialize(path, diff_time, dns_map)
      @path = path
      @diff_time = diff_time
      @log_entries = Hash.new{|h,k| h[k]=[] }
      @log_entries.extend(MonitorMixin)     
      @dns_map = dns_map

      @reader_thread = Thread.new{reader_thread_proc}
      @cleaner_thread = Thread.new{cleaner_thread_proc}
    end

    # Parses log line and adds it to buffer
    # @param [String] line Log file entry
    def parse_logline(line)        
      line.strip!
      split_line = line.split(/\|/)
      addr = split_line[0].split(',').last.strip

      unless (addr =~ /[\s|\-]+/)   
        @dns_map.synchronize do
          addr = @dns_map[addr] if @dns_map.include? addr
        end
        details = {}
        details[:upstream_response_time] = split_line[1].split(',').last.strip.to_f
        details[:time_local] = DateTime.strptime(split_line[2], '%d/%b/%Y:%H:%M:%S %Z')
        details[:status] = split_line[3].to_i
        details[:request_length] = split_line[4].to_i
        details[:body_bytes_sent] = split_line[5].to_i


        @log_entries.synchronize do
          @log_entries[addr] << details
        end
      end        
    end

    # Reader thread procedure for LogReader
    def reader_thread_proc
      begin
        File::Tail::Logfile.tail(@path, :backward => 10) do |line|
          begin
            parse_logline(line)
          rescue Exception => e
            puts "Malformed log line [#{line}]: #{e}"
          end
        end
      rescue Exception => e 
        puts "LogReader is dead: #{e}"
      end
    end

    # Cleans up entries that are older than diff
    # @param [Numeric] diff Maximal acceptable age of entry
    def delete_oldies(diff)
      @log_entries.synchronize do
        @log_entries.each_pair do |key, value|
          value.delete_if { |e| ((Time.now - e[:time_local].to_time) > diff)  }
        end
        @log_entries.delete_if { |key, value| value==[] } #jak zostanie pusta tablica, chyba ze dla historii chcemy przechowywac puste worker_addr'y (?)
      end
    end

    # Buffer cleaner thread procedure
    def cleaner_thread_proc
      while true
        delete_oldies(@diff_time)
        sleep(10)
      end
    end

    # Calculates statistics for given data
    # @param [Hash] Log data
    # @param [Symbol, String] id What attribute is concerned (:upstream_response_time, :request_length, :body_bytes_sent)
    # @return [Hash] Hash of statistics
    def get_stats_for_one(stat_entries, id)
      arr = stat_entries.extract(id)
      {max: arr.max, min: arr.min, avg: arr.avg, median: arr.median, stddev: arr.stddev}
    end

    # Calculates stats for worker
    # @param [String] worker_addr Worker address
    # @param [String] max_time Maximal age of log entries concerned
    # @return [Hash] Hash of statistics
    def get_stats_for_worker(worker_addr, maxtime)
      stats = {} 
      stat_entries = []
      @log_entries.synchronize do
        stat_entries = @log_entries[worker_addr].select { |item| (Time.now - item[:time_local].to_time) <= maxtime }
      end       
        
      stats[:request_count] = stat_entries.size
      stats[:response_time] = get_stats_for_one(stat_entries, :upstream_response_time)
      stats[:request_length] = get_stats_for_one(stat_entries, :request_length)
      stats[:response_length] = get_stats_for_one(stat_entries, :body_bytes_sent)

      stats
    end

  end
end