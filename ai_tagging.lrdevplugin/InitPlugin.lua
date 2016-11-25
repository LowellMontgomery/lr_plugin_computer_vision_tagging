--[[----------------------------------------------------------------------------

InitPlugin.lua
What to do when plugin is loaded?

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

local KmnUtils = require 'KmnUtils'

-- Provide initial default values for plugin preferences.
local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

local defaultPrefValues = {
   clarifai_clientsecret = '',
   clarifai_clientid = '',
   log_level = KmnUtils.LogTrace,
   tag_window_thumbnail_size = 256,
   tag_window_width = 1024,
   tag_window_height = 768,
   image_preview_window_width = 1024,
   image_preview_window_height = 768,
   tag_window_sort = KmnUtils.SortProb,
   tag_window_show_probabilities = true,
   tag_window_show_services = true,
   tag_window_bold_existing_tags = true,
   tag_window_auto_select_threshold = 85,
   -- ignore_keyword_branches = '',
   -- auto_select_existing_keywords = true,
}

if prefs ~= nil then
  for k,v in pairs(defaultPrefValues) do
     if prefs[k] == nil then prefs[k] = v end
  end
end

-- Setup logging AFTER defaults are set for the plugin
KmnUtils.enableDisableLogging()
