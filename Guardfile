# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec --next-failure --format progress' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { 'spec' }
  watch('spec/spec_helper.rb')  { 'spec' }
end
