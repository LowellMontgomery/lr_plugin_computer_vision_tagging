--[[----------------------------------------------------------------------------

HelpClarifaiUsage.lua
Builds dialog showing Clarifai API usage information

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

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrPrefs = import 'LrPrefs'
local KmnUtils = require 'KmnUtils'
local ClarifaiAPI = require 'ClarifaiAPI'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

local get_usage_result;
LrFunctionContext.callWithContext("get_info_result_table", function( context )
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiUsage.LrFunctionContext.callWithContext(get_info_result_table');
  get_usage_result = LrBinding.makePropertyTable( context );
  get_usage_result.user_throttles = {};
  get_usage_result.app_throttles = {};
end)

local function lookup_ui_user_throttles_tooltip(component)
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiUsage.lookup_ui_user_throttles_tooltip(component)');
  if component == 'consumed' then
    return 'How many units you have currently consumed.';
  elseif component == 'consumed_percentage' then
    return 'The percentage of consumed / limit.';
  elseif component == 'limit' then
    return 'The maximum number of units you can consume per month or hour. This can be changed by modifying your current plan.';
  elseif component == 'units' then
    return 'A short sentence similar to name.';
  elseif component == 'wait' then
    return 'Time in seconds until you should make a new request. If you\'re under the limit for the current interval, it\'s a suggestion to evenly space out requests over the interval. If you\'re over the limit, it\'s the required wait time till the limit resets.';
  end
  
  return nil;
end

local function lookup_ui_user_throttles_title(component)
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiUsage.lookup_ui_user_throttles_title(component)');
  if component == 'wait' then
    return "Wait (s)";
  elseif component == 'units' then
    return "Units";
  elseif component == 'consumed' then
    return 'Consumed Amount';
  elseif component == 'limit' then
    return 'Limit Per Unit';
  elseif component == 'consumed_percentage' then
    return 'Consumed (%)';
  end
  return nil;
end

local function ui_group_user_throttles(vf, bind)
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiUsage.ui_group_user_throttles(vf, bind)');
  local detail_rows = {};
  local row_count = 1;

  for throttle_type,values in pairs(get_usage_result.user_throttles) do
    local nested_detail_rows = {};
    local nested_row_count = 1;
    for throttle, throttle_value in pairs(values) do
      nested_detail_rows[nested_row_count] = vf:row {
        bind_to_object = values,
        vf:static_text {
          title = lookup_ui_user_throttles_title(throttle),
          font = '<system/bold>',
          tooltip = lookup_ui_user_throttles_tooltip(throttle),
        },
        vf:edit_field {
          enabled = false,
          value = bind(throttle),
        }
      };
      nested_row_count = nested_row_count + 1;
    end
    nested_detail_rows['title'] = throttle;
    detail_rows[row_count] = vf:group_box(nested_detail_rows);
    row_count = row_count + 1;
  end

  detail_rows['bind_to_object'] = get_usage_result.user_throttles;
  detail_rows['title'] = 'User Throttles';

  return vf:group_box(detail_rows);
end

LrFunctionContext.callWithContext( 'HelpClarifaiUsage', function( context )
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiUsage.LrFunctionContext.callWithContext(HelpClarifaiUsage)');
  LrFunctionContext.postAsyncTaskWithContext('Help.Clarifai.APIUsage', function()
    local clarifaiUsage = ClarifaiAPI.getUsage();
    for key,value in pairs(clarifaiUsage.results.app_throttles) do
      get_usage_result.app_throttles[key] = value;
    end
    for key,value in ipairs(clarifaiUsage.results.user_throttles) do
      local name = value.name;
      value.name = nil;
      get_usage_result.user_throttles[name] = value;
    end
    
    local vf = LrView.osFactory();
    local bind = LrView.bind;

    local contents = vf:view {
      bind_to_object = get_usage_result,
      vf:group_box {
        title = 'Please Note',
        vf:row {
          vf:static_text {
            title = 'Below are the usage details returned by the Clarifai API.\nThe values may take a second to populate, please be patient.',
            size = 'small',
            height_in_lines = 2,
          },
        }
      },
      vf:group_box {
        bind_to_object = get_usage_result.app_throttles,
        title = 'App Throttles',
        vf:row {
          vf:static_text {
            title = 'Unknown',
            font = '<system/bold>',
          },
          vf:static_text {
            title = 'These values are not processed currently (none seen in an API response to date)',
          },
        },
      },
      ui_group_user_throttles(vf, bind)
    };

    LrDialogs.presentModalDialog({
      title = 'Clarifai API Usage',
      contents = contents,
      resizable = true,
      actionVerb = 'OK',
      cancelVerb = '< exclude >'
    });
  end);
end);
