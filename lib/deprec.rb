unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"
require "#{File.dirname(__FILE__)}/deprec/recipes"

# The below: Copyright 2009-2010 by le1t0@github. All rights reserved.
# add missing standard tasks to the various namespaces, so generic scripts won't break, the standard tasks are for now:
standard_tasks = [
  :install,
  :config_gen,
  :config_project_gen,
  :config_system_gen,
  :config,
  :config_project,
  :config_system,
  :start,
  :stop,
  :restart,
  :reload,
  :activate,
  :deactivate,
  :backup,
  :restore,
  :status
]
Capistrano::Configuration.instance.deprec.namespaces.keys.each do |ns_name|
  ns = Capistrano::Configuration.instance.deprec.send(ns_name)
  standard_tasks.each do |standard_task|
    unless ns.respond_to?(standard_task)
      Capistrano::Configuration.instance.namespace :deprec do
        namespace ns_name do
          task standard_task do
            # nothing to be done here
          end
        end
      end
    end
  end
  unless ns.respond_to?(:check_roles)
    Capistrano::Configuration.instance.namespace :deprec do
      namespace ns_name do
        desc "check if all roles are defined for :#{ns_name}"
        task :check_roles do
          user_defined_roles = roles.keys
          recipe_declared_roles = Capistrano::Configuration.instance.deprec.send(ns_name).tasks.collect { |k,v| v.options.has_key?(:roles) ? v.options[:roles] : nil }.compact.flatten.uniq
          
          missing_roles = recipe_declared_roles - user_defined_roles
          
          abort "You should define role(s): #{missing_roles.join(', ')}" unless missing_roles.empty?
        end
      end
    end
  end
  unless ns.respond_to?(:diff_config)
    Capistrano::Configuration.instance.namespace :deprec do
      namespace ns_name do
        desc "perform local/remote diff on project configs for :#{ns_name}"
        task :diff_config_project do
          PROJECT_CONFIG_FILES[ns_name].each do |config_file|
            deprec2.compare_files(ns_name, config_file[:path], config_file[:path])
          end if defined?(PROJECT_CONFIG_FILES) && PROJECT_CONFIG_FILES[ns_name]
        end

        desc "perform local/remote diff on system configs for :#{ns_name}"
        task :diff_config_system do
          SYSTEM_CONFIG_FILES[ns_name].each do |config_file|
            deprec2.compare_files(ns_name, config_file[:path], config_file[:path])
          end if defined?(SYSTEM_CONFIG_FILES) && SYSTEM_CONFIG_FILES[ns_name]
        end

        desc "perform local/remote diff on all configs for :#{ns_name}"
        task :diff_config do
          diff_config_system
          diff_config_project
        end
      end
    end
  end
end
