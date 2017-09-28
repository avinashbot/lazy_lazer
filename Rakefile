# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new do |task|
  task.options = ['-D', '-E', '-S']
end
RSpec::Core::RakeTask.new(:spec)

task default: %i[rubocop spec]
