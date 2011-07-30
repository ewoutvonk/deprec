# Copyright 2009-2010 by le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  def glusterfs_generate_volfiles(glusterfs_exports, glusterfs_defaults, &block)
    temp_dir = Time.now.strftime("/tmp/%Y%m%d%H%M%S.glusterfs.tmp")
    sudo "mkdir -p #{temp_dir}"
    glusterfs_exports.each do |name, cfg|
      opts = [ "-n \"#{name}\"" ]
      opts << ((cfg[:port] || glusterfs_defaults[:port]) ? "-p #{cfg[:port] || glusterfs_defaults[:port]}" : nil)
      opts << ((cfg[:transport] || glusterfs_defaults[:transport]) ? "-t #{cfg[:transport] || glusterfs_defaults[:transport]}" : nil)
      opts << ((cfg[:auth] || glusterfs_defaults[:auth]) ? "-a \"#{cfg[:auth] || glusterfs_defaults[:auth]}\"" : nil)
      opts << ((cfg[:raid] || glusterfs_defaults[:raid]) ? "-r #{cfg[:raid] || glusterfs_defaults[:raid]}" : nil)
      [cfg[:servers] || glusterfs_defaults[:servers]].flatten.each do |server| opts << "#{server}:#{cfg[:store_dir] || glusterfs_defaults[:store_dir]}" end
      sudo "glusterfs-volgen -c #{temp_dir} #{opts.compact.join(" ")}"
      yield(temp_dir, name, cfg) if block_given?
    end
    sudo "rm -f #{temp_dir}/*"
    sudo "rmdir #{temp_dir}"
  end
  
  namespace :deprec do
    namespace :glusterfs do
      
      set :glusterfs_defaults, { }
      set :glusterfs_exports, { }
      set :glusterfs_client_config_local, { }
      
      # DON'T use this one, it's only used for internal purposes
      set :glusterfs_client_config_contents, ""
            
      SRC_PACKAGES[:glusterfs] = {
        :md5sum => "e2eaf3d1e7a735ee7e7b262a46bbc75d  glusterfs-3.0.4.tar.gz", 
        :url => "http://ftp.gluster.com/pub/gluster/glusterfs/3.0/3.0.4/glusterfs-3.0.4.tar.gz",
        :configure => './configure --prefix=/usr;',
        :make => 'make;',
        :install => 'make install;'
      }

      SYSTEM_CONFIG_FILES[:glusterfs] = [
        {:template => "glusterfsd-init.erb",
         :path => '/etc/init.d/glusterfsd',
         :mode => 0755,
         :owner => 'root:root'}
      ]
      
      desc "Install glusterfs (from source)"
      task :install, :roles => [ :storage_client, :storage_server ] do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:glusterfs], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:glusterfs], src_dir)
      end
      
      task :install_deps, :roles => [ :storage_client, :storage_server ] do
        apt.install( {:base => %w(sshfs build-essential flex bison byacc fuse-utils libfuse-dev)}, :stable )
      end

      desc "Generate configuration file(s) for Glusterfs from template(s)"
      task :config_gen do
        glusterfs_client_config_local.each do |name, contents|
          set :glusterfs_client_config_contents, contents
          cfg = glusterfs_exports[name]
          deprec2.render_template(:glusterfs, {
            :template => "glusterfs.vol.erb",
            :path => "/etc/glusterfs/#{name}-#{cfg[:transport] || glusterfs_defaults[:transport] || 'tcp'}.vol",
            :mode => 0644,
            :owner => 'root:root'
          })
        end
        set :glusterfs_client_config_contents, ""
        SYSTEM_CONFIG_FILES[:glusterfs].each do |file|
          deprec2.render_template(:glusterfs, file)
        end
      end

      desc "Create glusterfs config files on server"
      task :config do
        config_client
        config_server
      end

      desc "Create glusterfs client config files on server"
      task :config_client, :roles => :storage_client do
        sudo "mkdir -p /etc/glusterfs 2>/dev/null || exit 0"
        if glusterfs_client_config_local
          system_config_files = [] # we can start empty, as we don't need the init file on the clients
          glusterfs_exports.each do |name, cfg|
            system_config_files << {
              :template => "glusterfs.vol.erb",
              :path => "/etc/glusterfs/#{name}-#{cfg[:transport] || glusterfs_defaults[:transport] || 'tcp'}.vol",
              :mode => 0644,
              :owner => 'root:root'
            }
          end
          deprec2.push_configs(:glusterfs, system_config_files)
        else
          glusterfs_generate_volfiles(glusterfs_exports, glusterfs_defaults) do |temp_dir, name, cfg|
            sudo "mkdir -p #{cfg[:mount_dir] || glusterfs_defaults[:mount_dir]}"
            sudo "mv #{temp_dir}/#{name}-#{cfg[:transport] || glusterfs_defaults[:transport] || 'tcp'}.vol /etc/glusterfs/"
          end
        end
      end

      desc "Create glusterfs server config files on server"
      task :config_server, :roles => :storage_server do
        sudo "mkdir -p /etc/glusterfs 2>/dev/null || exit 0"
        deprec2.push_configs(:glusterfs, SYSTEM_CONFIG_FILES[:glusterfs])
        glusterfs_generate_volfiles(glusterfs_exports, glusterfs_defaults) do |temp_dir, name, cfg|
          sudo "mkdir -p #{cfg[:store_dir] || glusterfs_defaults[:store_dir]}"
          sudo "mv #{temp_dir}/$(ip addr | grep -o -e #{(cfg[:servers] || glusterfs_defaults[:servers]).map do |ip| "'#{ip}'" end.join(" -e ")})-#{name}-export.vol /etc/glusterfs/"
        end
      end

      desc "Start Glusterfs"
      task :start do
        start_server
        start_client
      end

      desc "Start Glusterfs"
      task :start_client, :roles => :storage_client do
        glusterfs_exports.each do |name, cfg|
          send(run_method, "mount #{cfg[:mount_dir] || glusterfs_defaults[:mount_dir]} || exit 0")
        end
      end

      desc "Start Glusterfs"
      task :start_server, :roles => :storage_server do
        send(run_method, "/etc/init.d/glusterfsd start")
      end

      desc "Stop Glusterfs"
      task :stop do
        stop_client
        stop_server
      end

      desc "Stop Glusterfs"
      task :stop_client, :roles => :storage_client do
        glusterfs_exports.each do |name, cfg|
          send(run_method, "umount #{cfg[:mount_dir] || glusterfs_defaults[:mount_dir]} || exit 0")
        end
      end

      desc "Stop Glusterfs"
      task :stop_server, :roles => :storage_server do
        send(run_method, "/etc/init.d/glusterfsd stop")
      end

      desc "Restart Glusterfs"
      task :restart do
        restart_server
        restart_client
      end

      desc "Restart Glusterfs"
      task :restart_client do
        stop_client
        start_client
      end

      desc "Restart Glusterfs"
      task :restart_server do
        stop_server
        start_server
      end

      desc "Set Glusterfs to start on boot"
      task :activate do
        activate_server
        activate_client
      end
      
      desc "Set Glusterfs to start on boot"
      task :activate_client, :roles => :storage_client do
        glusterfs_exports.each do |name, cfg|
          deprec2.append_to_file_if_missing('/etc/fstab', "/etc/glusterfs/#{name}-#{cfg[:transport] || glusterfs_defaults[:transport] || 'tcp'}.vol  #{cfg[:mount_dir] || glusterfs_defaults[:mount_dir]}  glusterfs,_netdev  defaults  0  0")
        end
      end
      
      desc "Set Glusterfs to start on boot"
      task :activate_server, :roles => :storage_server do
        send(run_method, "update-rc.d glusterfsd defaults")
      end
      
      desc "Set Glusterfs to not start on boot"
      task :deactivate do
        deactivate_server
        deactivate_client
      end
      
      desc "Set Glusterfs to not start on boot"
      task :deactivate_client, :roles => :storage_client do
        glusterfs_exports.each do |name, cfg|
          send(run_method, "perl -p -i -e 's#/etc/glusterfs/#{name}-#{cfg[:transport] || glusterfs_defaults[:transport] || 'tcp'}.vol  #{cfg[:mount_dir] || glusterfs_defaults[:mount_dir]}  glusterfs,_netdev  defaults  0  0\\s+##' /etc/fstab")
        end
      end
      
      desc "Set Glusterfs to not start on boot"
      task :deactivate_server, :roles => :storage_server do
        send(run_method, "update-rc.d -f glusterfsd remove")
      end
      
    end
  end
end