# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec -fp' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { 'spec' }
  watch('spec/spec_helper.rb')  { 'spec' }
end
