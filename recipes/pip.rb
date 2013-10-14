#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Cookbook Name:: python
# Recipe:: pip
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if platform_family?("rhel", "ubuntu") and node['python']['install_method'] == 'package'
  pip_binary = "/usr/bin/pip"
elsif platform_family?("smartos")
  pip_binary = "/opt/local/bin/pip"
else
  pip_binary = "/usr/local/bin/pip"
end

# Ubuntu's python-setuptools, python-pip and python-virtualenv packages
# are broken...this feels like Rubygems!
# http://stackoverflow.com/questions/4324558/whats-the-proper-way-to-install-pip-virtualenv-and-distribute-for-python
# https://bitbucket.org/ianb/pip/issue/104/pip-uninstall-on-ubuntu-linux
# http://s3.pixane.com/pip_distribute.png
cookbook_file "#{Chef::Config[:file_cache_path]}/distribute_setup.py" do
  mode "0644"
  action :create_if_missing
  not_if { ::File.exists?(pip_binary) }
end

execute "install-pip" do
  cwd Chef::Config[:file_cache_path]
  command <<-EOF
#{node['python']['binary']} distribute_setup.py; easy_install pip;
  EOF
  not_if { ::File.exists?(pip_binary) }
end

if node[:python][:pip][:config]
  search('users', "groups:#{node[:python][:pip][:users_group]} AND NOT action:remove") do |user|
    user['username'] ||= user['id']

    if user['home']
      home_dir = user['home']
    else
      home_dir = "/home/#{user['username']}"
    end

    directory "#{home_dir}/.pip" do
      owner user['id']
    end

    template "#{home_dir}/.pip/pip.conf" do
      owner user['id']
      group user['id']
      mode 0644
      source "pip.conf.erb"
    end

    directory node[:python][:pip][:cache_dir] do
      mode 0777
      recursive true
    end
  end
end
