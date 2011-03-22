# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :redis do
      
      set :redis_user, 'redis'
      set :redis_group, 'redis'
      set :redis_ports, "6379" # comma separated list of ports
      
      SRC_PACKAGES[:redis] = {
        :md5sum => '1c5b0d961da84a8f9b44a328b438549e  redis-2.2.2.tar.gz',
        :url => "http://redis.googlecode.com/files/redis-2.2.2.tar.gz",
        :configure => nil,
      }
      
      desc "install Redis"
      task :install do
        create_redis_user
        deprec2.download_src(SRC_PACKAGES[:redis], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:redis], src_dir)
      end
    
      SYSTEM_CONFIG_FILES[:redis] = [
        
        {:template => "redis-init.erb",
         :path => '/etc/init.d/redis_@@PORT@@',
         :mode => 0755,
         :owner => 'root:root'},

        {:template => "redis-conf.erb",
         :path => '/etc/redis/redis_@@PORT@@.conf',
         :mode => 0755,
         :owner => 'root:root'}
        
      ]
      
      desc <<-DESC
      Generate redis config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          set :redis_port, port
          SYSTEM_CONFIG_FILES[:redis].each do |file|
            file_settings = file.dup
            file_settings[:path].gsub!(/@@PORT@@/, port.to_s)
            deprec2.render_template(:redis, file_settings)
          end
        end
      end

      desc "Push redis config files to server"
      task :config, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          SYSTEM_CONFIG_FILES[:redis].each do |file|
            file_settings = file.dup
            file_settings[:path].gsub!(/@@PORT@@/, port.to_s)
            deprec2.push_configs(:redis, [file_settings])
          end
        end
      end

      task :create_redis_user, :roles => :redis do
        deprec2.groupadd(redis_group)
        deprec2.useradd(redis_user, :group => redis_group, :homedir => false)
      end

      desc "Start Redis"
      task :start, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          send(run_method, "/etc/init.d/redis_#{port} start")
        end
      end

      desc "Stop Redis"
      task :stop, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          send(run_method, "/etc/init.d/redis_#{port} stop")
        end
      end

      desc "Restart Redis"
      task :restart, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          send(run_method, "/etc/init.d/redis_#{port} restart")
        end
      end

      desc "Set Redis to start on boot"
      task :activate, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          send(run_method, "update-rc.d redis_#{port} defaults")
        end
      end
      
      desc "Set Redis to not start on boot"
      task :deactivate, :roles => :redis do
        (ENV['PORTS'] || redis_ports).split(/,/).each do |port|
          send(run_method, "update-rc.d -f redis_#{port} remove")
        end
      end

      desc "Clean out old redis configs and init files"
      task :cleanup, :roles => :redis do
        sudo "/etc/init.d/redis stop"
        sudo "rm -f /etc/init.d/redis"
        sudo "mv /etc/redis/redis.conf /etc/redis/redis.conf.deprecated"
        sudo "update-rc.d -f redis remove"
      end
      
    end 
  end
end