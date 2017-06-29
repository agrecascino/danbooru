set :user, "danbooru"
set :rails_env, "production"
server "ec2-13-59-92-103.us-east-2.compute.amazonaws.com", :roles => %w(web app db), :primary => true, :user => "danbooru"

set :linked_files, fetch(:linked_files, []).push(".env.production")
