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

#install project vendors
composer_project "/srv/www/classifieds_carsifu/current/carsifu-v2" do
    dev false
    quiet true
    prefer_dist false
    action :install
end

execute "chown" do
  command "chown -R deploy:www-data srv/www/classifieds_carsifu/current/carsifu-v2/vendor; chown -R deploy:www-data srv/www/classifieds_carsifu/current/carsifu-v2/composer.lock"
  action :run
end

execute "chmod-775" do
  command "chmod 775  /srv/www/carsifu/current/automania-v2/wp-content/cache; chmod 775  /srv/www/carsifu/current/automania-v2/wp-content/uploads; chmod 775  /srv/www/carsifu/current/automania-v2/wp-content/w3tc-config; chmod 775  -R /srv/www/classifieds_carsifu/current/carsifu-v2/storage/framework; chmod 775  -R /srv/www/classifieds_carsifu/current/carsifu-v2/storage/logs; chmod a+x  /srv/www/classifieds_carsifu/current/carsifu-v2/vendor/monolog/monolog/src/Monolog/Handler"
  action :run
end

execute "php artisan" do
  command "php #{deploy[:deploy_to]}/current/carsifu-v2 artisan migrate"
  only_if do
    if node[:opsworks][:layers]['php-app'] && node[:opsworks][:layers]['php-app'][:instances].empty?
       # no 'online' php servers --> we are the first one booting
       true
    elsif node[:opsworks][:instance][:hostname] == node[:opsworks][:layers]['php-app'][:instances].keys.sort.first
       # we are the first 'online' php-app server
       true
    else
      # we are not the first one
      false
    end
  end
end

end
