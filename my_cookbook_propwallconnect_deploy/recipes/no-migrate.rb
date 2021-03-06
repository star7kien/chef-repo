##
# Cookbook Name:: my_cookbook
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node[:deploy].each do |application, deploy|

  app_root = "#{deploy[:deploy_to]}/current/storage"
  directory app_root do
    owner 'deploy'
    group 'www-data'
    mode '0777' 
    action :create
  end

#directory "#{deploy[:deploy_to]}/current/vendor" do
#  owner 'deploy'
#  group 'www-data'
#  mode '0777'
#  action :create
#end

execute "chmod-775" do
  command "chmod -R 775  #{deploy[:deploy_to]}/current/storage/app; chmod -R 777  #{deploy[:deploy_to]}/current/storage/framework; chmod -R 777  #{deploy[:deploy_to]}/current/storage/logs; chmod -R 775 #{deploy[:deploy_to]}/current/bootstrap/cache"
  action :run
end

#node[:deploy][:domains].each  do |domain|
#  command "echo newrelic.appname = #{domain} >> #{deploy[:deploy_to]}/current/.htaccess"
#end
execute "add Newrelic Appname" do
#  command "echo php_value newrelic.appname = #{deploy[:domains].first} >> #{deploy[:deploy_to]}/current/.htaccess"
  command %Q[echo php_value newrelic.appname "#{deploy[:domains].first}" >> #{deploy[:deploy_to]}/current/public/.htaccess]
  action :run
end

#Add php5-mcrypt to cli/conf.d
execute "add mcrypt symlink" do
  command "ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini"
  action :run
  not_if { ::File.exists?("/etc/php5/cli/conf.d/20-mcrypt.ini")}
end

#Add copy App variable to .env file
template "#{deploy[:deploy_to]}/current/.env" do
  source "laravel_env.erb"
  mode 0440
  owner deploy[:user]
  group deploy[:group]
  variables(
    :environment => OpsWorks::Escape.escape_double_quotes(deploy[:environment_variables])
  )
end

# install composer.
include_recipe "composer::default"

directory "/root/.composer" do
  mode '775'
  action :create
end

template "/root/.composer/auth.json" do
  source "composer_auth_json.erb"
end

#install project vendors
composer_project "#{deploy[:deploy_to]}/current" do
#    dev "node[:composer][:dev]"
    dev true
    quiet true
    prefer_dist false
    action :install
end

#execute "chown" do
#  command "chown -R deploy:www-data #{deploy[:deploy_to]}/current/vendor"
#  action:run
#end

end
