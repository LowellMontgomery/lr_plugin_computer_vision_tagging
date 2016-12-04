--[[----------------------------------------------------------------------------

Info.lua
Summary information for computer vision tagging plugin

--------------------------------------------------------------------------------

    Copyright 2016 Mike "KemoNine" Crosson
 
    This file is part of the LRCVT program.

    LRCVT is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License.

    LRCVT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with LRCVT.  If not, see <http://www.gnu.org/licenses/>.


------------------------------------------------------------------------------]]

local menuItems = { { title = LOC '$$$/ComputerVisionTagging/MenuClarifaiInfo=Clarifai API Info', file = 'MenuClarifaiInfo.lua' },
                    { title = LOC '$$$/ComputerVisionTagging/menuClarifaiUsage=Clarifai API Usage', file = 'MenuClarifaiUsage.lua' },
}

local version = { major=2016, minor=12, revision=03, build=1, };
version.display = version.major .. version.minor .. version.revision .. '.' .. version.build;

return {

  LrSdkVersion = 6.0,
  LrSdkMinimumVersion = 5.0,

  LrToolkitIdentifier = 'info.kemonine.lrcvt',
  LrPluginName = LOC "$$$/ComputerVisionTagging/PluginName=Computer Vision Tagging",
  LrPluginInfoUrl = 'https://mcrosson.github.io/lr_plugin_computer_vision_tagging/',
  
  LrAlsoUseBuiltInTranslations = true,
  LrLimitNumberOfTempRenditions = true,
  
  LrInitPlugin = 'InitPlugin.lua',

  LrExportMenuItems = menuItems,
  LrHelpMenuItems = menuItems,

  LrPluginInfoProvider = 'PluginInfoProvider.lua',
  
  LrExportServiceProvider = {
    title = LOC '$$$/ComputerVisionTagging/Title=Computer Vision Tagging',
    file = 'ExportServiceProvider.lua',
    builtInPresetsDir = 'cvtPresets',
  },
  
  VERSION = version,

}
