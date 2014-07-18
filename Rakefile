require 'rake/clean'

CLEAN.include('build/*')

namespace :build do
  desc 'Runs a debug build'
  task :debug do
    sh 'dub'
  end

  desc 'Runs a unit test build'
  task :test do
    sh 'dub --build=unittest'
  end
end

task :default => ['build:debug']
