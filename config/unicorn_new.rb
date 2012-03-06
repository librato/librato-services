# From: https://gist.github.com/206253

rails_env = ENV['RAILS_ENV'] || 'production'
base_dir = ENV['UNICORN_WORKDIR'] || ENV['PWD']

# 8 workers and 1 master
worker_processes (rails_env == 'production' ? 8: 4)

# Load site into the master before forking workers
# for super-fast worker spawn times
preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 30

# Listen on a Unix data socket
listen File.join(base_dir, ENV['UNICORN_SOCK']), :backlog => 2048

pid File.join(base_dir, 'tmp/pids/unicorn.pid')

# This ensures Unicorn will respawn in the correct directory even if
# the symlink changes.
working_directory base_dir

stdout_path File.join(base_dir, 'log/unicorn.stdout.log')
stderr_path File.join(base_dir, 'log/unicorn.stderr.log')

##
# REE

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# Invoked before a SIGUSR2 respawns a new Unicorn master
before_exec do |server|
  # Need to reset the environment from ENVIRON_FILE.
  # XXX: This doesn't handle unsetting a variable.
  #
  if ENV['ENVIRON_FILE'] && File.exist?(ENV['ENVIRON_FILE'])
    File.readlines(ENV['ENVIRON_FILE']).each do |line|
      r = /^([A-Za-z0-9_]+)=(.*)$/
      m = line.match(r)
      next unless m

      var, value = [m[1], m[2]]

      # Need to remove leading and trailing ' or " from value
      value.chomp!('"')
      value.chomp!("'")

      value = value[1..-1] if %w[ " ' ].include?(value[0,1])

      # Finally, update the variable
      ENV[var] = value
    end
  end
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = File.join(base_dir, 'tmp/pids/unicorn.pid.oldbin')
  if File.exists?(old_pid) && server.pid.to_i != File.read(old_pid).to_i
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end


after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  #CHIMNEY.client.connect_to_server
  # Redis and Memcached would go here but their connections are established
  # on demand, so the master never opens a socket


  ##
  # Unicorn master is started as root, which is fine, but let's
  # drop the workers to metrics

  # begin
  #   uid, gid = Process.euid, Process.egid
  #   user, group = 'metrics', 'metrics'
  #   target_uid = Etc.getpwnam(user).uid
  #   target_gid = Etc.getgrnam(group).gid
  #   worker.tmp.chown(target_uid, target_gid)
  #   if uid != target_uid || gid != target_gid
  #     Process.initgroups(user, target_gid)
  #     Process::GID.change_privilege(target_gid)
  #     Process::UID.change_privilege(target_uid)
  #   end
  # rescue => e
  #   if Rails.env == 'development'
  #     STDERR.puts "couldn't change user, oh well"
  #   else
  #     raise e
  #   end
  # end
end
