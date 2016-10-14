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

local LrPrefs = import 'LrPrefs'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'
local LrColor = import 'LrColor'
local PlugInfo = require 'Info'
local KmnUtils = require 'KmnUtils'
local ClarifaiAPI = require 'ClarifaiAPI'

local prefs = LrPrefs.prefsForPlugin();

local function currentOrDefaultValue(value, default)
   if value == nil then
      return default
   end
   return value
end

local function sectionsForTopOfDialog(viewFactory, properties)
  local vf = viewFactory;
  local bind = LrView.bind;
  
  -- Ensure various default values are setup
  prefs.log_level = currentOrDefaultValue(prefs.log_level, KmnUtils.LogError);
  prefs.sort = currentOrDefaultValue(prefs.sort, KmnUtils.SortProb);
  prefs.thumbnail_size = currentOrDefaultValue(prefs.thumbnail_size, 256);
  prefs.tag_window_width = currentOrDefaultValue(prefs.tag_window_width, 1024);
  prefs.tag_window_height = currentOrDefaultValue(prefs.tag_window_height, 768);
  prefs.tag_window_show_probabilities = currentOrDefaultValue(prefs.tag_window_show_probabilities, true);
  prefs.bold_existing_tags = currentOrDefaultValue(prefs.bold_existing_tags, true);
  prefs.clarifai_clientid = currentOrDefaultValue(prefs.clarifai_clientid, '');
  prefs.clarifai_clientsecret = currentOrDefaultValue(prefs.clarifai_clientsecret, '');
  
  -- Setup observer pattern so results of verification of API can be marked success/fail
  local get_info_result;
  LrFunctionContext.callWithContext("get_info_result_table", function( context )
    get_info_result = LrBinding.makePropertyTable( context );
    get_info_result.message = 'Success';
    get_info_result.color = LrColor('green');
    get_info_result.visible = false;
  end)
  
  return {
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/Info=Computer Vision Tagging Plugin',
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
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/Global=Global',
      bind_to_object = prefs,
      vf:row {
        spacing = vf:control_spacing(),
        vf:checkbox {
          title = 'Bold exising keywords/tags',
          checked_value = true,
          unchecked_value = false,
          value = bind 'bold_existing_tags',
        },
      },
      vf:row { 
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/preferences/Global/TagSort=Tag Sorting',
          tooltip = 'How to sort tags in tagging dialog',
        },
        vf:popup_menu {
          tooltip = 'How to sort tags in tagging dialog',
          items = {
            { title = 'Probability', value = KmnUtils.SortProb },
            { title = 'Alphabetical', value = KmnUtils.SortAlpha },
          },
          value = bind 'sort',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/Preferences/Global/LogLevel=Log Level',
          tooltip = 'How verbose the log output will be',
        },
        vf:popup_menu {
          tooltip = 'How verbose the log output will be',
          items = {
            { title = 'Fatal', value = KmnUtils.LogFatal },
            { title = 'Error', value = KmnUtils.LogError },
            { title = 'Warn', value = KmnUtils.LogWarn },
            { title = 'Info', value = KmnUtils.LogInfo },
            { title = 'Debug', value = KmnUtils.LogDebug },
            { title = 'Trace ', value = KmnUtils.LogTrace  },
            { title = 'Disabled', value = KmnUtils.LogDisabled },
          },
          value = bind 'log_level',
        },
      },
    },
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/TagWindow=Tag Window',
      bind_to_object = prefs,
      vf:row {
        spacing = vf:control_spacing(),
        vf:checkbox {
          title = 'Show Probabilities in Tag Window',
          checked_value = true,
          unchecked_value = false,
          value = bind 'tag_window_show_probabilities',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = 'Thumbnail size',
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog'
        },
        vf:slider {
          value = bind 'thumbnail_size',
          min = 128,
          max = 512,
          integral = true,
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog'
        },
        vf:edit_field {
          value = bind 'thumbnail_size',
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog',
          fill_horizonal = 1,
          width_in_chars = 4,
          min = 128,
          max = 512,
          increment = 1,
          precision = 0,
        }
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = 'Tagging window width',
          tooltip = 'Width (px) of the tagging window',
        },
        vf:edit_field {
          value = bind 'tag_window_width',
          tooltip = 'Width (px) of the tagging window',
          min = 512,
          max = 999999,
          width_in_chars = 7,
          increment = 1,
          precision = 0,
        }
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = 'Tagging window height',
          tooltip = 'Height (px) of the tagging window',
        },
        vf:edit_field {
          value = bind 'tag_window_height',
          tooltip = 'Height (px) of the tagging window',
          min = 384,
          max = 999999,
          width_in_chars = 7,
          increment = 1,
          precision = 0,
        }
      },
    },
    {
      title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings=Clarifai Settings',
      bind_to_object = prefs,
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings/ClientID=Client ID',
        },
        vf:edit_field {
          fill_horizonal = true,
          width_in_chars = 35,
          value = bind 'clarifai_clientid',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings/ClientSecret=Client Secret',
        },
        vf:password_field {
          fill_horizontal = true,
          width_in_chars = 35,
          value = bind 'clarifai_clientsecret',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings/AccessToken=Access Token',
        },
        vf:edit_field {
          enabled = false,
          fill_horizontal = true,
          width_in_chars = 35,
          value = bind 'clarifai_accesstoken',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:push_button {
          title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings/VerifySettings=Verify Settings',
          action = function(button)
                      LrFunctionContext.postAsyncTaskWithContext('ClarifaiSettings.VerifySettingsButton', function()
                        local clarifaiInfo = ClarifaiAPI.getInfo();
                        if clarifaiInfo ~= nil then
                          get_info_result.message = 'Success';
                          get_info_result.color = LrColor('green');
                        else
                          get_info_result.message = 'Failure';
                          get_info_result.color = LrColor('red');
                        end
                        get_info_result.visible = true;
                      end); 
                   end
        },
        vf:push_button {
          title = LOC '$$$/ComputerVisionTagging/Preferences/ClarifaiSettings/GenerateAccessToken=Generate New Access Token',
          action = function(button)
                      ClarifaiAPI.getToken()
                   end
        },
      },
      vf:row {
        spacing = vf:label_spacing(),
        vf:static_text {
          bind_to_object = get_info_result,
          title = bind 'message',
          text_color = bind 'color',
          visible = bind 'visible',
        },
      },
    },
  }
end

local function sectionsForBottomOfDialog(viewFactory, properties)
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

local function endDialog(properties)
  -- Ensure logging is turned on/off if pref changed
  KmnUtils.enableDisableLogging();
  
  -- Generate Clarifai access token if it's missing/empty
  if prefs.clarifai_accesstoken == nil or prefs.clarifai_accesstoken == '' then
    ClarifaiAPI.getToken();
   end
end


return {
  sectionsForTopOfDialog = sectionsForTopOfDialog,
  sectionsForBottomOfDialog = sectionsForBottomOfDialog,
  endDialog = endDialog,
}
