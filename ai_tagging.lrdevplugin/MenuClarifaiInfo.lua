--[[----------------------------------------------------------------------------

HelpClarifaiInfo.lua
Builds dialog shown when selecting Clarifai Info from help menu

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
local KmnUtils = require 'KmnUtils'
local ClarifaiAPI = require 'ClarifaiAPI'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

local get_info_result;
LrFunctionContext.callWithContext("get_info_result_table", function( context )
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiInfo.LrFunctionContext.callWithContext(get_info_result_table)');
  get_info_result = LrBinding.makePropertyTable( context );
  get_info_result.max_video_batch_size = -1;
  get_info_result.max_image_size = -1;
  get_info_result.max_image_bytes = -1;
  get_info_result.api_version = -1;
  get_info_result.max_video_size = -1;
  get_info_result.max_video_bytes = -1;
  get_info_result.min_video_size = -1;
  get_info_result.max_batch_size = -1;
  get_info_result.min_image_size = -1;
  get_info_result.default_language = '';
  get_info_result.max_video_duration = -1;
  get_info_result.default_model = '';
end)

LrFunctionContext.callWithContext( 'HelpClarifaiInfo', function( context )
  KmnUtils.log(KmnUtils.LogTrace, 'MenuClarifaiInfo.LrfunctionContext.callWithContext(HelpClarifaiInfo)');
  LrFunctionContext.postAsyncTaskWithContext('Help.Clarifai.APIInfo', function()
    local clarifaiInfo = ClarifaiAPI.getInfo();
        get_info_result.max_video_batch_size = clarifaiInfo.results.max_video_batch_size;
        get_info_result.max_image_size = clarifaiInfo.results.max_image_size;
        get_info_result.max_image_bytes = clarifaiInfo.results.max_image_bytes;
        get_info_result.api_version = clarifaiInfo.results.api_version;
        get_info_result.max_video_size = clarifaiInfo.results.max_video_size;
        get_info_result.max_video_bytes = clarifaiInfo.results.max_video_bytes;
        get_info_result.min_video_size = clarifaiInfo.results.min_video_size;
        get_info_result.max_batch_size = clarifaiInfo.results.max_batch_size;
        get_info_result.min_image_size = clarifaiInfo.results.min_image_size;
        get_info_result.default_language = clarifaiInfo.results.default_language;
        get_info_result.max_video_duration = clarifaiInfo.results.max_video_duration;
        get_info_result.default_model = clarifaiInfo.results.default_model;
  end);
  
  local vf = LrView.osFactory();
  local bind = LrView.bind;
  
  local contents = vf:view {
    bind_to_object = get_info_result,
    vf:group_box {
      title = 'Please Note',
      vf:row {
        vf:static_text {
          title = 'Below are the API details and any usage limits for the configured account.\nHover over the title of a value for a full description.\nThe values may take a second to populate, please be patient.',
          size = 'small',
          height_in_lines = 3,
        },
      }
    },
    vf:group_box {
      title = 'General Info',
      vf:row {
        vf:static_text {
          title = 'API Version',
          font = '<system/bold>',
          tooltip = 'The API version as set by the relative path prefix in the URL.'
        },
        vf:edit_field {
          enabled = false,
          value = bind 'api_version',
          tooltip = 'The API version as set by the relative path prefix in the URL.'
        },
      },
      vf:row {
        vf:static_text {
          title = 'Default Language',
          font = '<system/bold>',
          tooltip = 'The language returned when no language parameter is sent as part of an API request.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'default_language',
          tooltip = 'The language returned when no language parameter is sent as part of an API request.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Default model',
          font = '<system/bold>',
          tooltip = 'The model returned when no model parameter is sent as part of an API request.'
        },
        vf:edit_field {
          enabled = false,
          value = bind 'default_model',
          tooltip = 'The model returned when no model parameter is sent as part of an API request.'
        },
      },
    },
    vf:group_box {
      title = 'Photo Limits',
      vf:row {
        vf:static_text {
          title = 'Minimum Image Size',
          font = '<system/bold>',
          tooltip = 'The minimum allowed image size (on the minimum dimension). Any images that have a minimum dimension (width or height) less than this limit will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'min_image_size',
          tooltip = 'The minimum allowed image size (on the minimum dimension). Any images that have a minimum dimension (width or height) less than this limit will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Maximum Image Size',
          font = '<system/bold>',
          tooltip = 'The maximum allowed image size (on the minimum dimension). Any images that have a minimum dimension (width or height) greater than this limit will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_image_size',
          tooltip = 'The maximum allowed image size (on the minimum dimension). Any images that have a minimum dimension (width or height) greater than this limit will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Max Image Size (bytes)',
          font = '<system/bold>',
          tooltip = 'The maximum allowed image number of bytes. Any images that exceed this limit in size will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_image_bytes',
          tooltip = 'The maximum allowed image number of bytes. Any images that exceed this limit in size will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Max Image Batch Size',
          font = '<system/bold>',
          tooltip = 'The maximum number of images allowed to process in one batch request.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_batch_size',
          tooltip = 'The maximum number of images allowed to process in one batch request.',
        },
      },
    },
    vf:group_box {
      title = 'Video Limits',
      vf:row {
        vf:static_text {
          title = 'Minimum Video Size',
          font = '<system/bold>',
          tooltip = 'The minimum allowed video size (on the minimum dimension). Any videos that have a minimum dimension less than this limit will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'min_video_size',
          tooltip = 'The minimum allowed video size (on the minimum dimension). Any videos that have a minimum dimension less than this limit will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Maximum Video Size',
          font = '<system/bold>',
          tooltip = 'The maximum allowed video size (on the minimum dimension). Any videos that have a minimum dimension greater than this limit will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_video_size',
          tooltip = 'The maximum allowed video size (on the minimum dimension). Any videos that have a minimum dimension greater than this limit will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Maximum Video Duration',
          font = '<system/bold>',
          tooltip = 'The maximum allowed video duration in seconds. Any videos that exceed this limit in duration will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_video_duration',
          tooltip = 'The maximum allowed video duration in seconds. Any videos that exceed this limit in duration will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Maximum Video Size (bytes)',
          font = '<system/bold>',
          tooltip = 'The maximum allowed video number of bytes. Any videos that exceed this limit in size will not be processed.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_video_bytes',
          tooltip = 'The maximum allowed video number of bytes. Any videos that exceed this limit in size will not be processed.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Max Video Batch Size',
          font = '<system/bold>',
          tooltip = 'The maximum number of videos allowed to process in one batch request.',
        },
        vf:edit_field {
          enabled = false,
          value = bind 'max_video_batch_size',
          tooltip = 'The maximum number of videos allowed to process in one batch request.',
        },
      },
    },
  };
    
  LrDialogs.presentModalDialog({ 
    title = 'Clarifai API Info',
    contents = contents,
    resizable = true,
    actionVerb = 'OK',
    cancelVerb = '< exclude >'
  })
  end
);
