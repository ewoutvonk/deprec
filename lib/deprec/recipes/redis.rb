# Copyright 2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :redis do
      
      set :redis_user, 'redis'
      set :redis_group, 'redis'
      set :redis_ports, [6379]
      
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
        redis_ports.each do |port|
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
        redis_ports.each do |port|
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
        send(run_method, "/etc/init.d/redis start")
      end

      desc "Stop Redis"
      task :stop, :roles => :redis do
        send(run_method, "/etc/init.d/redis stop")
      end

      desc "Restart Redis"
      task :restart, :roles => :redis do
        send(run_method, "/etc/init.d/redis restart")
      end

      desc "Set Redis to start on boot"
      task :activate, :roles => :redis do
        send(run_method, "update-rc.d redis defaults")
      end
      
      desc "Set Redis to not start on boot"
      task :deactivate, :roles => :redis do
        send(run_method, "update-rc.d -f redis remove")
      end
      
    end 
  end
end