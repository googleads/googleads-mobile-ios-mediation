# frozen_string_literal: true

# Copyright 2026 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Removes every adapter that is not under test from AdapterUnitTests.xcodeproj.
#
# AdapterUnitTests.xcodeproj references every adapter's Xcode project as a
# subproject. xcodebuild resolves the Swift packages of every project in the
# workspace, whichever scheme is built, so without this script testing one
# adapter also fetches the Swift packages of all the other adapters. This script
# removes the subprojects of the adapters that are not listed, together with
# their test targets and shared schemes.
#
# Kokoro runs this script before `pod install`. It modifies the checked-in
# project, so to use it locally, run it from this directory and restore the
# project when you are done:
#
#   export ADAPTER_TARGETS="AdapterTargetName"
#   ruby scope_unit_test_project.rb
#   pod install
#   ...
#   bash pod_deintegrate.sh
#   git checkout AdapterUnitTests.xcodeproj  # Or the equivalent in your VCS.
#
# Usage: ruby scope_unit_test_project.rb [AdapterTargetName...]
#
# The adapters to keep are the arguments or, if there are none, the
# comma-separated ADAPTER_TARGETS environment variable, using the same adapter
# target names as the Podfile. With no adapters to keep, the script does
# nothing. Running it again with the same adapters does nothing.

require 'fileutils'
require 'xcodeproj'

PROJECT_PATH = File.expand_path('AdapterUnitTests.xcodeproj', __dir__)

# Returns the names of the adapters to keep.
def adapters_to_keep(args)
  names = args.empty? ? ENV.fetch('ADAPTER_TARGETS', '').split(',') : args
  names.map(&:strip).reject(&:empty?)
end

# Returns the targets that build against the given subproject, either by linking
# one of its products or by depending on one of its targets.
def targets_using_subproject(project, subproject_file, products)
  project.targets.select do |target|
    links_product = target.build_phases.any? do |phase|
      phase.files.any? { |build_file| products.include?(build_file.file_ref) }
    end
    depends_on_target = target.dependencies.any? do |dependency|
      dependency.target_proxy&.container_portal == subproject_file.uuid
    end
    links_product || depends_on_target
  end
end

# Removes a target, its product and its shared scheme from the project.
def remove_target(project, target)
  scheme_path = Xcodeproj::XCScheme.shared_data_dir(project.path) + "#{target.name}.xcscheme"
  FileUtils.rm_f(scheme_path)
  target.product_reference&.remove_from_project
  target.remove_from_project
end

# Removes the given subproject reference and everything that points at it.
def remove_subproject(project, reference)
  subproject_file = reference[:project_ref]
  product_group = reference[:product_group]
  products = product_group.children.to_a

  targets_using_subproject(project, subproject_file, products).each do |target|
    remove_target(project, target)
  end

  project.objects.each do |object|
    case object
    when Xcodeproj::Project::Object::PBXBuildFile
      object.remove_from_project if products.include?(object.file_ref)
    when Xcodeproj::Project::Object::PBXTargetDependency
      object.remove_from_project if object.target_proxy&.container_portal == subproject_file.uuid
    end
  end
  project.objects.each do |object|
    if object.is_a?(Xcodeproj::Project::Object::PBXContainerItemProxy) &&
       object.container_portal == subproject_file.uuid
      object.remove_from_project
    end
  end

  products.each(&:remove_from_project)
  product_group.remove_from_project
  project.root_object.project_references.delete(reference)
  subproject_file.remove_from_project
end

def main(args)
  adapters = adapters_to_keep(args)
  if adapters.empty?
    puts 'No adapters to keep; leaving AdapterUnitTests.xcodeproj unchanged.'
    return
  end

  project = Xcodeproj::Project.open(PROJECT_PATH)
  references_to_remove = project.root_object.project_references.reject do |reference|
    adapters.include?(File.basename(reference[:project_ref].path, '.xcodeproj'))
  end
  if references_to_remove.empty?
    puts "AdapterUnitTests.xcodeproj already only references #{adapters.join(', ')}."
    return
  end

  references_to_remove.each do |reference|
    puts "Removing #{File.basename(reference[:project_ref].path)} and its test targets."
    remove_subproject(project, reference)
  end
  project.save
end

main(ARGV)
