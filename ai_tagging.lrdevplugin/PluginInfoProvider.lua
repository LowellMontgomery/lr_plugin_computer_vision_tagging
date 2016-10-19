--[[----------------------------------------------------------------------------

PluginInfoProvider.lua
Plugin settings / info UI

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

local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'
local LrColor = import 'LrColor'
local PlugInfo = require 'Info'
local KmnUtils = require 'KmnUtils'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)
local InfoProvider = {}

function InfoProvider.sectionsForTopOfDialog(viewFactory, properties)
  KmnUtils.log(KmnUtils.LogTrace, 'InfoProvider.sectionsForTopOfDialog(viewFactory, properties)');
  local vf = viewFactory
  local bind = LrView.bind
  
  -- Setup observer pattern so results of verification of API can be marked success/fail
--  local get_info_result;
--  LrFunctionContext.callWithContext("get_info_result_table", function( context )
--    get_info_result = LrBinding.makePropertyTable( context );
--    get_info_result.message = 'Success';
--    get_info_result.color = LrColor('green');
--    get_info_result.visible = false;
--  end)
  
  return {
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/VersionTitle=Computer Vision Tagging Plugin',
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/Preferences/Version=Version',
        },
        vf:edit_field {
          enabled = false,
          value = PlugInfo.VERSION.display,
        }
      },
    },
  };
end

function InfoProvider.sectionsForBottomOfDialog(viewFactory, properties)
  KmnUtils.log(KmnUtils.LogTrace, 'InfoProvider.sectionsForBottomOfDialog(viewFactory, properties)');
  local vf = viewFactory;
  
  return {
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/Acknowledgements=Acknowledgements',

      vf:static_text {
        title = LOC '$$$/ComputerVisionTagging/Preferences/SimpleJSON=Simple JSON',
      },
      vf:edit_field {
        width_in_chars = 80,
        height_in_lines = 9,
        enabled = false,
        value = 'Simple JSON encoding and decoding in pure Lua.\n\nCopyright 2010-2016 Jeffrey Friedl\nhttp://regex.info/blog/\n\nLatest version: http://regex.info/blog/lua/json\n\nThis code is released under a Creative Commons CC-BY "Attribution" License:\nhttp://creativecommons.org/licenses/by/3.0/deed.en_US\n'
      }
    }
  }
end

function InfoProvider.endDialog(properties)
  KmnUtils.log(KmnUtils.LogTrace, 'InfoProvider.endDialog(properties)');
  -- Ensure logging is turned on/off if pref changed
  KmnUtils.enableDisableLogging();
end


return InfoProvider
