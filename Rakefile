require "rake/testtask"

Rake::TestTask.new do |task|
  task.libs << "lib"
  task.pattern = "test/**/*_test.rb"
end

desc "Run reproducible Ruby benchmarks"
task :benchmark do
  ruby "benchmarks/benchmark.rb"
end

namespace :native do
  desc "Build the optional Zig backend"
  task :build do
    Dir.chdir("native/zig") { sh "zig", "build", "-Doptimize=ReleaseFast" }
  end
end

task default: :test
