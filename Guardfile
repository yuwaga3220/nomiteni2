# frozen_string_literal: true

# https://github.com/guard/guard-minitest

guard :minitest, cmd: "bin/rails test" do
  watch(%r{^test/.*_test\.rb$})
  watch(%r{^test/test_helper\.rb$}) { "test" }

  watch(%r{^app/controllers/application_controller\.rb$}) { "test/controllers" }

  watch(%r{^app/controllers/(.+)_controller\.rb$}) do |m|
    "test/controllers/#{m[1]}_controller_test.rb"
  end

  watch(%r{^app/views/layouts/}) { "test/controllers" }

  watch(%r{^app/views/([^/]+)/}) do |m|
    "test/controllers/#{m[1]}_controller_test.rb"
  end

  watch(%r{^config/routes\.rb$}) { "test/controllers" }

  watch(%r{^app/models/(.+)\.rb$}) do |m|
    "test/models/#{m[1]}_test.rb"
  end

  watch(%r{^lib/(.+)\.rb$}) do |m|
    "test/lib/#{m[1]}_test.rb"
  end
end
