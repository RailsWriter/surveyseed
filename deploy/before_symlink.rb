rails_env = new_resource.environment["RAILS_ENV"]

Chef::Log.info("Precompiling assets for RAILS_ENV=#{rails_env}...")

run "cd #{release_path} && RAILS_ENV=production bundle exec rake assets:precompile"