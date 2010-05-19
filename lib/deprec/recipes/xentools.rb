# Copyright 2006-2010 by Mike Bailey, le1t0@github. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :xentools do
        
      SRC_PACKAGES[:xentools] = {
        :url => "http://www.xen-tools.org/software/xen-tools/xen-tools-4.1.tar.gz",
        :md5sum => "156ec5991f3885ef0daa58c3424d0a35  xen-tools-4.1.tar.gz",
        :configure => '',
        :make => ''
      }
      
      desc "Install xen-tools"
      task :install, :roles => :dom0 do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:xentools], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:xentools], src_dir)
        initial_config
      end

      task :install_deps, :roles => :dom0 do
        # Cheeky way to ensure we have the dependencies - Mike
        apt.install( {:base => %w(xen-tools libexpect-perl)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:xentools] = [

        {:template => "xen-tools.conf.erb",
         :path => '/etc/xen-tools/xen-tools.conf',
         :mode => 0644,
         :owner => 'root:root'},
 
        {:template => "xm.tmpl.erb",
         :path => '/etc/xen-tools/xm.tmpl',
         :mode => 0644,
         :owner => 'root:root'},
         
         # This one is a bugfix for gutsy 
         {:template => "15-disable-hwclock",
          :path => '/usr/lib/xen-tools/gutsy.d/15-disable-hwclock',
          :mode => 0755,
          :owner => 'root:root'},

         # This one is a bugfix for gutsy: domU -> domU networking is screwy
         # http://lists.xensource.com/archives/html/xen-users/2006-05/msg00818.html
         {:template => "40-setup-networking",
          :path => '/usr/lib/xen-tools/gutsy.d/40-setup-networking',
          :mode => 0755,
          :owner => 'root:root'},
         
         # bugfix: #/bin/sh -> #!/bin/sh
         # bugfix: $i => $1
         {:template => "100-ubuntu-setup",
          :path => '/usr/lib/xen-tools/gutsy.d/100-ubuntu-setup',
          :mode => 0755,
          :owner => 'root:root'},

         # bugfix: make sure serial device is created and correct file is edited (/etc/inittab is not used anymore!)
         {:template => "30-disable-gettys",
          :path => '/usr/lib/xen-tools/gutsy.d/30-disable-gettys',
          :mode => 0755,
          :owner => 'root:root'},

         # bugfix: removed serial device code, since that's already performed in 30-disable-gettys
         # bugfix: #/bin/sh -> #!/bin/sh
         {:template => "31-ubuntu-setup",
          :path => '/usr/lib/xen-tools/gutsy.d/31-ubuntu-setup',
          :mode => 0755,
          :owner => 'root:root'},

         # added script for user adjustments to debootstrap results
         # modify this file inside your project (i.e. not in deprec itself) to added your own xen-tools steps
         {:template => "98-custom",
          :path => '/usr/lib/xen-tools/gutsy.d/98-custom',
          :mode => 0755,
          :owner => 'root:root'}
      ]
      
      task :initial_config, :roles => :dom0 do
        # Non-standard! We're pushing these straight out
        SYSTEM_CONFIG_FILES[:xentools].each do |file|
          deprec2.render_template(:xentools, file.merge(:remote => true))
        end
      end
      
      desc "Generate configuration file(s) for xen-tools from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:xentools].each do |file|
          deprec2.render_template(:xentools, file)
        end
      end

      desc "Push xen-tools config files to server"
      task :config, :roles => :dom0 do
        deprec2.push_configs(:xentools, SYSTEM_CONFIG_FILES[:xentools])
      end
      
    end
    
  end
end