# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec --format progress --fail-fast' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { 'spec' }
  watch('spec/spec_helper.rb')  { 'spec' }
end
