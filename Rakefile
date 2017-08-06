# coding: UTF-8

task :default => [:test]

namespace :docker do
  desc 'Build all docker images'
  task build: ['docker:app:build']

  namespace :app do
    desc 'Build the bestgems-app image'
    task :build do |t|
      sh 'docker build -t bestgems-app -f docker/bestgems-app/Dockerfile .'
    end

    desc 'Run tests inside a container'
    task :test do |t|
      sh 'docker run -it --rm bestgems-app rake'
    end
  end

  desc 'Up all docker containers using `docker-compose up`'
  task :up do |t|
    sh 'docker-compose -f docker/docker-compose.yml up'
  end
end

namespace 'db' do
  desc 'Execute migration'
  task :migration do |t|
    require_relative 'lib/migration/migrator'

    migrator = Migrator.new(settings.db)
    migrator.execute_migration()
  end
end

require 'rake/testtask'
Rake::TestTask.new do |test|
  ENV['APP_ENV'] = 'test' unless ENV['APP_ENV']

  test.test_files =  Dir['test/**/test_*.rb']
  test.verbose = true
end
