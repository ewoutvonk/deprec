# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :mri do
            
      SRC_PACKAGES[:mri] = {
        :md5sum => "18dcdfef761a745ac7da45b61776afa5  ruby-1.8.7-p174.tar.gz", 
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p174.tar.gz",
        :configure => "CXXFLAGS='-m32' CFLAGS=\"-m32\" LDFLAGS=\"-m32\" ./configure --host=i686-pc-linux --target=i686-pc-linux --build=i686-pc-linux --with-readline-dir=/usr/local;"
      }
  
      desc "Install Ruby"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:mri], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:mri], src_dir)
        top.deprec.rubygems.install
      end
      
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev)}, :stable )
        top.deprec.ubuntu.install_32bit_libs_support
        sudo "getlibs -p libssl0.9.8 || true"
        sudo "ln -nsf /usr/lib32/libssl.so.0.9.8 /usr/lib32/libssl.so"
        sudo "ln -nsf /usr/lib32/libcrypto.so.0.9.8 /usr/lib32/libcrypto.so"
      end

    end
  end
  
  
  namespace :deprec do
    namespace :rubygems do
  
      SRC_PACKAGES[:rubygems] = {
        :md5sum => "e85cfadd025ff6ab689375adbf344bbe  rubygems-1.3.7.tgz", 
        :url => "http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz",
	    :configure => "",
	    :make =>  "",
        :install => 'ruby setup.rb;'
      }
      
      desc "Install Rubygems"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:rubygems], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:rubygems], src_dir)
        # gem2.upgrade #  you may not want to upgrade your gems right now
      end
      
      # install dependencies for rubygems
      task :install_deps do
      end
      
    end
    
  end
end
