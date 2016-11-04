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
local LrHttp = import 'LrHttp'
local PlugInfo = require 'Info'
local KmnUtils = require 'KmnUtils'
local ClarifaiAPI = require 'ClarifaiAPI'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)
local InfoProvider = {}

function InfoProvider.sectionsForTopOfDialog(viewFactory, properties)
  KmnUtils.log(KmnUtils.LogTrace, 'InfoProvider.sectionsForTopOfDialog(viewFactory, properties)');
  local vf = viewFactory
  local bind = LrView.bind
  
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
      title = LOC '$$$/ComputerVisionTagging/Preferences/VersionTitle=Computer Vision Tagging Plugin',
      vf:row {
        vf:static_text {
          title = 'Website',
          text_color = LrColor('blue'),
          font = '<system/bold>',
          mouse_down = function (clickedview)
            LrHttp.openUrlInBrowser( 'https://mcrosson.github.io/lr_plugin_computer_vision_tagging/' );
          end
        },
        vf:static_text {
          title = 'Changelog',
          text_color = LrColor('blue'),
          font = '<system/bold>',
          mouse_down = function (clickedview)
            LrHttp.openUrlInBrowser( 'https://mcrosson.github.io/lr_plugin_computer_vision_tagging/changelog/' );
          end
        },
        vf:picture {
          value = _PLUGIN:resourceId('icon_download.png'),
        },
        vf:static_text {
          title = 'Releases',
          text_color = LrColor('blue'),
          font = '<system/bold>',
          mouse_down = function (clickedview)
            LrHttp.openUrlInBrowser( 'https://mcrosson.github.io/lr_plugin_computer_vision_tagging/releases/' );
          end
        },
        vf:picture {
          value = _PLUGIN:resourceId('icon_rss.png'),
        },
        vf:static_text {
          title = 'Subscribe (Releases)',
          text_color = LrColor('blue'),
          font = '<system/bold>',
          mouse_down = function (clickedview)
            LrHttp.openUrlInBrowser( 'https://mcrosson.github.io/lr_plugin_computer_vision_tagging/feed.xml' );
          end
        },
      },
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
        spacing = vf:label_spacing(),
        vf:static_text {
          title = LOC '$$$/ComputerVisionTagging/preferences/ignoreKeywordTreeBranches=Ignore keywords branches:',
          tooltip = 'Comma-separated list of keyword terms to ignore (including chilren and descendants).',
          alignment = 'left',
        },
        viewFactory:edit_field {
          tooltip = 'Comma-separated list of keyword terms to ignore (including chilren and descendants).',
          width_in_chars = 35,
          height_in_lines = 4,
          enabled = true,
          alignment = 'left',
          value = bind 'ignore_keyword_branches',
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
        vf:static_text {
          title = 'Tag Sorting',
          tooltip = 'How to sort tags in tagging dialog',
        },
        vf:popup_menu {
          tooltip = 'How to sort tags in tagging dialog',
          items = {
            { title = 'Probability', value = KmnUtils.SortProb },
            { title = 'Alphabetical', value = KmnUtils.SortAlpha },
          },
          value = bind 'tag_window_sort',
        },
      },
      vf:row {
      spacing = vf:control_spacing(),
        vf:checkbox {
          title = LOC '$$$/ComputerVisionTagging/preferences/autoSelectExistingKeywords=Automatically Select Existing Keywords',
          checked_value = true,
          unchecked_value = false,
          tooltip = "Selecting this option will auto-select keyword checkboxes which would *not* create a new term in your keyword list.",
          value = bind 'auto_select_existing_keywords',
        },
      },
      vf:row {
        spacing = vf:control_spacing(),
        vf:checkbox {
          title = 'Bold existing keywords/tags',
          checked_value = true,
          unchecked_value = false,
          value = bind 'tag_window_bold_existing_tags',
        },
      },
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
        vf:checkbox {
          title = 'Show service(s) that a tag was suggested by',
          checked_value = true,
          unchecked_value = false,
          value = bind 'tag_window_show_services',
        },
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
      vf:row {
        spacing = vf:control_spacing(),
        vf:static_text {
          title = 'Thumbnail size',
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog'
        },
        vf:slider {
          value = bind 'tag_window_thumbnail_size',
          min = 128,
          max = 512,
          integral = true,
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog'
        },
        vf:edit_field {
          value = bind 'tag_window_thumbnail_size',
          tooltip = 'Size (px) for the smallest edge of thumbnails in the tagging dialog',
          fill_horizonal = 1,
          width_in_chars = 4,
          min = 128,
          max = 512,
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
          fill_horizonal = 1,
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
                        local hasClarifaiInfo = false; -- do this the "dumb" way thanks to #clarifaiInfo not working properly
                        for _,__ in pairs(clarifaiInfo) do
                          hasClarifaiInfo = true;
                          break;
                        end
                        if clarifaiInfo ~= nil and hasClarifaiInfo then
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
        vf:push_button {
          title = 'Clear Access Token',
          action = function(button)
                      prefs.clarifai_accesstoken = '';
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
        font = '<system/bold>',
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
