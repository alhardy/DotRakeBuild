root_folder = "#{File.dirname(__FILE__)}/.."
 
Folders = {
    :root => root_folder,
    :src => "#{root_folder}/src",
    :out => {
        :root_folder => "#{root_folder}/out/",
        :published_websites => "#{root_folder}/out/_PublishedWebsites/**",
        :published_applications => "#{root_folder}/out/_PublishedApplications/**",
        :mstest_results => "#{root_folder}/out/_MsTestResults/",
        :artifacts => "#{root_folder}/out/_Artifacts/",
        :logs => "#{root_folder}/out/_Logs/"
    }
}
 
Tools ={
    :mstest => "C:/Program Files (x86)/Microsoft Visual Studio 10.0/Common7/IDE/mstest.exe"
}
 
Environment = {
    :build_name => ENV["build_name"] || "LocalBuild",
    :build_buildKey => ENV["build_key"] || "LocalKey",
    :build_number => ENV["build_number"] || "0",
    :build_time_stamp => ENV["buld_time_stamp"] || "",
    :build_configuration => ENV["configuration"] || "Debug",
    :build_environment => ENV["build_environment"] || "LocalEnv",
    :package_if_tests_fail => ENV["package_if_tests_fail"] || false
}
 
Project = {
    :company_name => "Your Company",
    :product_name => "Your Product",
    :copyright => "Copyright (C) 2012 Your Company",
}
 
Files = {
    :slns => {        
        :fullbuild => "#{root_folder}/YourSolutionFileName.sln"
    },
    :version => "VERSION",
    :global_assembly_info => "#{root_folder}/src/CommonAssemblyInfo.cs",
    :tests => {
        :mstest_assemblies => "#{Folders[:out][:root_folder]}/*.*Tests.dll",
        :mstest_results => "#{Folders[:out][:root_folder]}/_MsTestResults/testresults.trx",
        :mstest_settings => "#{Folders[:root]}/Test/LocalTestRun.testrunconfig"
    }
}