require 'rubygems'
$: << './'
 
require 'albacore'
require 'semver'
require 'rake/clean'
 
require 'config'
 
TESTING_PASSED=false
 
desc "**Default**, Builds, tests and packages artifacts"
task :default, [:build_configuration] => [:packageIt] do |t, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration])
end
 
desc "Builds test solution"
task :buildTests, [:build_configuration, :solution] do |t, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration], :solution => Files[:slns][:test])
  puts "Building test solution #{args.solution} with #{args.build_configuration} configuration"
  Rake::Task[:buildIt].reenable
  Rake::Task[:buildIt].invoke(args.build_configuration, args.solution)
  Rake::Task[:buildIt].reenable
end
 
desc "Just builds the solution"
msbuild :buildIt, [:build_configuration, :solution] => [:init, :versionIt] do |msb, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration], :solution => Files[:slns][:fullbuild])
  puts "building: build name #{Environment[:build_name]} for environment #{Environment[:build_environment]}"
  solution = args.solution
  puts "building #{solution} with #{args.build_configuration} configuration"
  msb.properties :configuration => args.build_configuration, :Bamboo_BuildPlanName => Environment[:build_name]
  msb.targets :Clean, :Build
  msb.solution = solution
  msb.verbosity = "normal"
  msb.parameters "/p:RunCodeAnalysis=False;UseWPP_CopyWebApplication=True;PipelineDependsOnBuild=False;OutDir=#{Folders[:out][:root_folder]};WebOutputFolder=#{Folders[:out][:published_websites]};AppOutputFolder=#{Folders[:out][:published_applications]} /l:FileLogger,Microsoft.Build;logfile=" + log_file("#{Folders[:out][:logs]}/build")
end
 
task :testIt, [:build_configuration] => [:buildTests] do |t, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration])
  begin
    Rake::Task[:mstest].invoke(args.build_configuration)
    TESTING_PASSED=true
  rescue RuntimeError => e
    TESTING_PASSED=Environment[:package_if_tests_fail]
    puts e
  end
end
 
desc "Runs all ms tests"
mstest :mstest, [:build_configuration]  => [:buildTests] do |mstest, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration])
  puts "running tests for: build name #{Environment[:build_name]} for environment #{Environment[:build_environment]}"
  testAssemblies = FileList[Files[:tests][:mstest_assemblies]].exclude(/obj\//)
  if !testAssemblies.nil? && testAssemblies.count > 0
    mstest.command = Tools[:mstest]
    mstest.assemblies testAssemblies
    mstest.parameters = "/resultsfile:#{Files[:tests][:mstest_results]} /runconfig:#{Files[:tests][:mstest_settings]}"
  else
    puts "There where no test assemblies found"
  end
end
 
desc "Modifies the global assembly file with the version defined in ./build/.semver"
assemblyinfo :versionIt do |asm|
  asm.product_name = Project[:product_name]
  asm.company_name = Project[:company_name]
  asm.copyright = Project[:copyright]
  asm.output_file = Files[:global_assembly_info]
 
  v = SemVer.find
  puts "appending #{Environment[:build_number]} to assembly version"
  asm.version = v.format "%M.%m.%p" + "." + Environment[:build_number]
  asm.file_version = v.format "%M.%m.%p" + "." + Environment[:build_number]
end
 
task :packageIt, [:build_configuration]  => [:init, :testIt, :packageApps, :packageWeb] do |t, args|
  args.with_defaults(:build_configuration => Environment[:build_configuration])
  puts "packing: build name #{Environment[:build_name]} for environment #{Environment[:build_environment]}"
end
 
 
desc "Creates artifacts for all compiled offline applications"
task :packageApps  => [:buildIt] do
  if TESTING_PASSED
    Dir[Folders[:out][:published_applications]].each do |dir|
      Rake::Task[:zip].reenable
      Rake::Task[:zip].invoke(dir)
    end
  else
    puts "Skipping artifacts as tests have failed"
  end
end
 
desc "Creates artifacts for all compiled web applications"
task :packageWeb => [:buildIt] do
  if TESTING_PASSED
    Dir[Folders[:out][:published_websites]].each do |dir|
      Rake::Task[:zip].reenable
      Rake::Task[:zip].invoke(dir)
    end
  else
    puts "Skipping artifacts as tests have failed"
  end
end
 
zip :zip, [:dir] do |zip, args|
  puts "zipping: #{args[:dir]}"
  zip.directories_to_zip args[:dir]
  zip.output_file = "#{File.basename(args[:dir])}-#{Environment[:build_environment]}-#{env_buildversion}.zip"
  zip.output_path =  Folders[:out][:artifacts]
end
 
task :init do
  puts "Initialising..."
  puts "Environment Variables"
  puts "Build Name: #{Environment[:build_name]}"
  puts "Build Key: #{Environment[:build_buildKey]}"
  puts "Build Number: #{Environment[:build_number]}"
  puts "Build Time Stamp: #{Environment[:build_time_stamp]}"
  puts "Build Configuration: #{Environment[:build_configuration]}"
  puts "Build Environment: #{Environment[:build_environment]}"
  puts "Build Revision Number: #{Environment[:build_revision_number]}"
  puts "Build Results Url: #{Environment[:build_resutls_url]}"
  FileUtils.rm_rf(Folders[:out][:root_folder], secure: true) if File.exists?(Folders[:out][:root_folder])
  FileUtils.mkdir Folders[:out][:root_folder]
  FileUtils.mkdir Folders[:out][:mstest_results]
  FileUtils.mkdir Folders[:out][:artifacts]
  FileUtils.mkdir Folders[:out][:logs]
end
 
def log_file(log_file_name)
  log_file_name + ".log"
end
 
def env_buildversion
  v = SemVer.find
  v.to_s + ".build." + Environment[:build_number]
end