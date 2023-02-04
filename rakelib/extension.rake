# frozen_string_literal: true

require "rb_sys/extensiontask"
require_relative "extension/cross_rubies"

RbSys::ExtensionTask.new("commonmarker", COMMONMARKER_SPEC) do |ext|
  ext.lib_dir = File.join("lib", "commonmarker")
end

task :setup do # rubocop:disable Rake/Desc
  require "rake_compiler_dock"
  RakeCompilerDock.sh(<<~EOT, verbose: true)
    gem update --system 3.3.22 --no-document &&
    bundle
  EOT
rescue => e
  warn(e.message)
end

namespace "gem" do
  CROSS_RUBIES.find_all { |cr| cr.windows? || cr.linux? || cr.darwin? }.map(&:platform).uniq.each do |platform|
    desc "build native gem for #{platform} platform"
    task platform do
      puts "Invoking RakeCompilerDock for #{platform} ..."
      require "rake_compiler_dock"
      RakeCompilerDock.sh(<<~EOT, verbose: true)
        gem update --system 3.3.22 --no-document &&
        bundle
      EOT
    rescue => e
      warn(e.message)
    end

    namespace platform do
      desc "build native gem for #{platform} platform (guest container)"
      task "builder" do
        puts "Invoking native:#{platform} ..."
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        puts "Invoking #{"pkg/#{COMMONMARKER_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"}  ..."

        Rake::Task["pkg/#{COMMONMARKER_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end

  desc "build native gems for windows"
  multitask "windows" => CROSS_RUBIES.find_all(&:windows?).map(&:platform).uniq

  desc "build native gems for linux"
  multitask "linux" => CROSS_RUBIES.find_all(&:linux?).map(&:platform).uniq

  desc "build native gems for darwin"
  multitask "darwin" => CROSS_RUBIES.find_all(&:darwin?).map(&:platform).uniq
end
