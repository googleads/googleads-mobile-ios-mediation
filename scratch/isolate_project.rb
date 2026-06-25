require 'xcodeproj'

proj_path = ARGV[0]
active_adapter = ARGV[1]
adapter_shortname = active_adapter.gsub('Adapter', '')

allowed_targets = [
  'AdapterUnitTestKit',
  'UnitTestHostApp',
  "#{adapter_shortname}AdapterTests",
  "#{adapter_shortname}AdapterLatencyTests"
]

puts "Allowed targets: #{allowed_targets.join(', ')}"

project = Xcodeproj::Project.open(proj_path)

# 1. Remove all targets that are not in the allowed list
project.targets.dup.each do |target|
  unless allowed_targets.include?(target.name)
    puts "Removing target: #{target.name}"
    target.remove_from_project
  end
end

# 2. Remove all subprojects that are not active_adapter, or if active_adapter is AppLovinAdapter
project.files.dup.each do |file|
  if file.path.end_with?('.xcodeproj')
    if !file.path.include?(active_adapter) || active_adapter == "AppLovinAdapter"
      puts "Removing subproject: #{file.path}"
      file.remove_from_project
    end
  end
end

# 3. Clean up dangling PBXContainerItemProxy objects
project.objects.select { |o| o.is_a?(Xcodeproj::Project::Object::PBXContainerItemProxy) }.each do |proxy|
  if project.objects_by_uuid[proxy.container_portal].nil?
    puts "Removing dangling container item proxy: #{proxy.uuid}"
    proxy.remove_from_project
  end
end

# 4. Clean up dangling PBXReferenceProxy objects
project.objects.select { |o| o.is_a?(Xcodeproj::Project::Object::PBXReferenceProxy) }.each do |ref_proxy|
  if ref_proxy.remote_ref.nil? || project.objects_by_uuid[ref_proxy.remote_ref.uuid].nil?
    puts "Removing dangling reference proxy: #{ref_proxy.path || ref_proxy.uuid}"
    ref_proxy.remove_from_project
  end
end

# 5. Clean up dangling PBXTargetDependency objects
project.objects.select { |o| o.is_a?(Xcodeproj::Project::Object::PBXTargetDependency) }.each do |dep|
  if dep.target_proxy.nil? || project.objects_by_uuid[dep.target_proxy.uuid].nil?
    puts "Removing dangling target dependency: #{dep.uuid}"
    dep.remove_from_project
  end
end

# 6. Remove target dependency of test targets on the subproject Adapter target to prevent parallel build race conditions
test_targets = project.targets.select { |t| t.name == "#{adapter_shortname}AdapterTests" || t.name == "#{adapter_shortname}AdapterLatencyTests" }
test_targets.each do |test_target|
  test_target.dependencies.dup.each do |dep|
    remote_info = dep.target_proxy&.remote_info
    if remote_info == "AdapterWithoutValidationScript" || remote_info == "Adapter"
      puts "Removing subproject target dependency #{remote_info} from test target: #{test_target.name}"
      dep.remove_from_project
    end
  end
end

# 7. Remove subproject's library product references from frameworks build phases to prevent Xcode from rebuilding subproject targets implicitly
test_targets.each do |test_target|
  next if test_target.frameworks_build_phase.nil?
  test_target.frameworks_build_phase.files.dup.each do |build_file|
    file_ref = build_file.file_ref
    next if file_ref.nil?

    if file_ref.is_a?(Xcodeproj::Project::Object::PBXReferenceProxy)
      # Find if the subproject matches the active adapter name
      subproject_file = project.files.find { |f| f.path.include?(active_adapter) && f.path.end_with?('.xcodeproj') }
      if subproject_file && file_ref.remote_ref&.container_portal == subproject_file.uuid
        puts "Removing subproject library reference from frameworks phase: #{file_ref.path || file_ref.name} in target #{test_target.name}"
        build_file.remove_from_project
      end
    end
  end
end

project.save
puts "Project isolation completed successfully."
