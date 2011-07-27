# Copyright 2006-2008 by Mike Bailey, 2011 by le1t0. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :memcache do
      
      set :memcache_ip, nil # -l ... -- memcached default is 'INDRR_ANY'
      set :memcache_port, nil # -p ... -- memcached default is '11211'
      set(:memcache_udp_port) { memcache_port } # -U ... -- defaults to memcache_port -- memcached default is '11211'
      set :memcache_memory, nil # -m ... -- memcached default is '64'
      set :memcache_factor, nil # -f ... -- memcached default is '1.25'
      set :memcache_minsize, nil # -n ... -- memcached default is '48'
      set :memcache_conn, nil # -c ... -- memcached default is '1024'
      set :memcache_run_as, nil # -u ...
      set :memcache_key_id_delim, nil # -D ... -- memcached default is ':'
      set :memcache_threads, nil # -t ... -- memcached default is '4'
      set :memcache_reqs_per_event, nil # -R ... -- memcached default is '20'
      set :memcache_backlog_queue_limit, nil # -b ... -- memcached default is '1024'
      set :memcache_binding_protocol, nil # -B auto|binary|ascii -- memcached default is 'auto'
      set :memcache_slab_page_size, nil # -I [1k..128m] -- memcached default is '1m'
      set :memcache_max_core_file_limit, false # -r -- memcached default is <not enabled>
      set :memcache_error_on_mem_exhausted, false # -M -- memcached default is <not enabled>
      set :memcache_lock_down_paged_mem, false # -k -- memcached default is <not enabled>
      set :memcache_large_memory_pages, false # -L -- memcached default is <not enabled>
      set :memcache_no_cas, false # -C -- memcached default is to use CAS
      
      MEMCACHED_BOOLEAN_OPTIONS = {
        :memcache_no_cas => :C,
        :memcache_large_memory_pages => :L,
        :memcache_lock_down_paged_mem => :k,
        :memcache_error_on_mem_exhausted => :M,
        :memcache_max_core_file_limit => :r
      }
      
      MEMCACHED_VALUE_OPTIONS = {
        :memcache_ip => :l,
        :memcache_port => :p,
        :memcache_udp_port => :U,
        :memcache_memory => :m,
        :memcache_factor => :f,
        :memcache_minsize => :n,
        :memcache_conn => :c,
        :memcache_run_as => :u,
        :memcache_key_id_delim => :D,
        :memcache_threads => :t,
        :memcache_reqs_per_event => :R,
        :memcache_backlog_queue_limit => :b,
        :memcache_binding_protocol => :B,
        :memcache_slab_page_size => :I
      }
  
      SYSTEM_CONFIG_FILES[:memcache] = [
    
        {:template => "memcache-init.d",
         :path => '/etc/init.d/memcached',
         :mode => 0755,
         :owner => 'root:root'}
     
      ]
  
      task :install, :roles => :memcached do
        version = 'memcached-1.4.6'
        set :src_package, {
          :file => version + '.tar.gz',   
          :md5sum => '243e5d82de27e6e45caf0ebfd400e41a  memcached-1.4.6.tar.gz', 
          :dir => version,  
          :url => "http://memcached.googlecode.com/files/#{version}.tar.gz",
          :unpack => "tar zxf #{version}.tar.gz;",
          :configure => %w{
            ./configure
            --prefix=/usr/local 
            ;
            }.reject{|arg| arg.match '#'}.join(' '),
          :make => 'make;',
          :install => 'make install;'
        }
        apt.install( {:base => %w(libevent-dev)}, :stable )
        deprec2.download_src(src_package, src_dir)
        deprec2.install_from_src(src_package, src_dir)
        sudo "mkdir /var/run/memcached"
        sudo "chown #{memcache_run_as} /var/run/memcached" if memcache_run_as
      end
  
      desc "Generate memcached configs"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:memcache].each do |file|
         deprec2.render_template(:memcache, file)
        end
      end

      desc "Push memcached config files (system & project level) to server"
      task :config, :roles => :memcached do
        deprec2.push_configs(:memcache, SYSTEM_CONFIG_FILES[:memcache])
        reload
      end

      desc "Start memcached"
      task :start, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached start"
      end
  
      desc "Stop memcached"
      task :stop, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached stop"
      end
  
      desc "Restart memcached"
      task :restart, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached restart"
      end
  
      desc "Reload memcached"
      task :reload, :roles => :memcached do
        run "#{sudo} /etc/init.d/memcached force-reload"
      end
  
      task :activate, :roles => :memcached do
        run "#{sudo} update-rc.d memcached defaults"
      end  
  
      task :deactivate, :roles => :memcached do
        run "#{sudo} update-rc.d -f memcached remove"
      end
  
    end
  end
end