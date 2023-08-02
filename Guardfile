# frozen_string_literal: true

group :red_green_refactor, halt_on_fail: true do
  guard :rspec, cmd: 'RAILS_ENV=test bundle exec rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^app/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { 'spec' }
  end

  guard :rubocop, all_on_start: false, cli: ['--auto-correct'] do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end
end

group 'specs', halt_on_fail: true do
  guard :bundler do
    watch('Gemfile')
  end
end