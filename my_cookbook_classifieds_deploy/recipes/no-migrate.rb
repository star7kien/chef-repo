##
# Cookbook Name:: my_cookbook
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node[:deploy].each do |application, deploy|

  app_root = "/srv/www/classifieds_carsifu/current/carsifu-v2/storage"
  directory app_root do
    owner 'deploy'
    group 'www-data'
    mode '0775' 
    recursive true
  end

  directory "#{deploy[:deploy_to]}/current/carsifu-v2/vendor" do
    owner 'deploy'
    group 'www-data'
    mode '0775' 
  end

#Add copy App variable to .env file
template "#{deploy[:deploy_to]}/current/carsifu-v2/.env" do
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

#directory "/srv/www/classifieds_carsifu/current/carsifu-v2/vendor" do
#  owner 'deploy'
#  group 'www-data'
#  mode '0777'
#  action :create
#end

#install project vendors
composer_project "/srv/www/classifieds_carsifu/current/carsifu-v2" do
    dev false
    quiet true
    prefer_dist false
    user "deploy"
    group "www-data"
    action :install
end

#execute "php artisan" do
#  command "php /srv/www/classifieds_carsifu/current/carsifu-v2/artisan migrate"
#  only_if do
#    if node[:opsworks][:layers]['php-app'] && node[:opsworks][:layers]['php-app'][:instances].empty?
#       # no 'online' php servers --> we are the first one booting
#       true
#    elsif node[:opsworks][:instance][:hostname] == node[:opsworks][:layers]['php-app'][:instances].keys.sort.first
#       # we are the first 'online' php-app server
#       true
#    else
#      # we are not the first one
#      false
#    end
#  end
#end

#file "/srv/www/classifieds_carsifu/current/carsifu-v2/composer.lock" do
#  owner "deploy"
#  group "www-data"
#end

#execute "chown" do
#  command "chown -R deploy:www-data srv/www/classifieds_carsifu/current/carsifu-v2/vendor"
#  action :run
#end

execute "chmod-775" do
  command "chmod 775  -R /srv/www/classifieds_carsifu/current/carsifu-v2/storage/logs"
  action :run
end

#execute "chmod-664" do
#	command "chmod 664 /srv/www/carsifu/current/automania-v2/.htaccess"
#	action :run
#end

end
