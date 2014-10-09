Pod::Spec.new do |s|
  s.name             = "MMPCoreDataHelper"
  s.version          = "0.7.5"
  s.summary          = "A straightforward CoreData wrapper"
  s.description      = <<-DESC
                       A lightweight helper library for common CoreData tasks providing data access pattern inspired by Active Record, LINQ, and functional programming.

                       Features:
                       * Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC (NSManagedObjectContext) belongs to the thread or not. The library makes sure that the MOC is local to the whichever thread you're calling the function from.
                       * Active Record, LINQ-like functional wrapper for common tasks.
                       * Automatic configuration and initialization (by convention over configuration) by default but manual configuration is still possible.
                       * Import data directly from CSV file.
                       * Get notified on errors and other CoreData events using NSNotificationCenter.                       
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPCoreDataHelper"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPCoreDataHelper.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.7'

  s.source_files     = 'Classes'
  s.framework        = 'CoreData'
  s.dependency 'MMPCSVUtil'
  s.requires_arc     = true  
end
