# Adds the PetWidget WidgetKit extension and the launch-link plugin to
# ios/Runner.xcodeproj. Safe to re-run: it does nothing if already applied.
#
#   GEM_HOME=/opt/homebrew/Cellar/cocoapods/<version>/libexec \
#     ruby tool/ios/add_widget_extension.rb
require 'xcodeproj'

project_path = File.expand_path('../../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |t| t.name == 'Runner' }

if project.targets.any? { |t| t.name == 'PetWidget' }
  puts 'PetWidget already added; nothing to do.'
  exit 0
end

team = app.build_configurations.map { |c| c.build_settings['DEVELOPMENT_TEAM'] }.compact.first

# --- Runner: launch-link plugin + App Group entitlements -------------------
runner_group = project.main_group['Runner']
app.source_build_phase.add_file_reference(runner_group.new_reference('LaunchLinkPlugin.swift'))
runner_group.new_reference('Runner.entitlements')
app.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# --- PetWidget extension target --------------------------------------------
widget = project.new_target(:app_extension, 'PetWidget', :ios, '14.0')
group = project.main_group.new_group('PetWidget', 'PetWidget')
widget.source_build_phase.add_file_reference(group.new_reference('PetWidget.swift'))
widget.resources_build_phase.add_file_reference(group.new_reference('Assets.xcassets'))
group.new_reference('Info.plist')
group.new_reference('PetWidget.entitlements')
xcconfig = group.new_reference('PetWidget.xcconfig')

# Flutter projects also have a Profile configuration.
unless widget.build_configurations.any? { |c| c.name == 'Profile' }
  release = widget.build_configurations.find { |c| c.name == 'Release' }
  profile = widget.add_build_configuration('Profile', :release)
  profile.build_settings.merge!(release.build_settings)
end

widget.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.thelazybearClub.myPetCat.PetWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'PetWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = 'PetWidget/PetWidget.entitlements'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SWIFT_VERSION'] = '5.0'
  s['SKIP_INSTALL'] = 'YES'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

# --- Embed the extension in the app ------------------------------------------
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13' # PlugIns
embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
app.add_dependency(widget)

# Flutter's "Thin Binary" script must run after embedding, or Xcode reports a
# build cycle.
app.build_phases.delete(embed)
thin = app.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
app.build_phases.insert(thin || app.build_phases.length, embed)

project.save
puts 'Added PetWidget extension.'
