# require 'resque/tasks'
# will give you the resque tasks

namespace :resque do
  task :setup

  desc "Start a Resque worker"
  task :work => [:pidfile, :setup] do
    require 'resque'

    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

    begin
      worker = Resque::Worker.new(*queues)
      worker.term_timeout = ENV['RESQUE_TERM_TIMEOUT'] || 4.0
    rescue Resque::NoQueueError
      abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    if ENV['BACKGROUND']
      unless Process.respond_to?('daemon')
          abort "env var BACKGROUND is set, which requires ruby >= 1.9"
      end
      Process.daemon(true)
      write_pidfile(worker.pid) if ENV['PIDFILE']
    end


    Resque.logger.info "Starting worker #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple Resque workers. Should only be used in dev mode."
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake resque:work"
      end
    end

    threads.each { |thread| thread.join }
  end

  desc 'Write a pidfile.'
  task :pidfile do
    write_pidfile(Process.pid) if ENV['PIDFILE']
  end

  def write_pidfile(pid)
    File.open(ENV['PIDFILE'], 'w') { |f| f << pid }
  end

end
