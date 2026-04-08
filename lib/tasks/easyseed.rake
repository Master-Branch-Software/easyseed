namespace :easyseed do
  desc "Back up db/seeds.rb and install the easyseed wrapper"
  task :init do
    Easyseed.install!
  end
end
