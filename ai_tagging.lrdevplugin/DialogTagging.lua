--[[----------------------------------------------------------------------------

DialogTagging.lua
Builds the tagging dialog that is shown at the end of export

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
-- local Require = require 'Require'.path ("../../debugscript.lrdevplugin")
-- local Debug = require 'Debug'.init ()
-- require 'strict'

local LrApplication = import 'LrApplication'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local KmnUtils = require 'KmnUtils'
local Tagging = require 'Tagging'
local ClarifaiAPI = require 'ClarifaiAPI'
local KwUtils = require 'KwUtils'
local LUTILS = require 'LUTILS'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

local vf = LrView.osFactory();
local bind = LrView.bind;
local share = LrView.share

LrTasks.startAsyncTask(function()
  local catalog = LrApplication.activeCatalog()
  local allKeys = KwUtils.getAllKeywords(catalog);
end);

local DialogTagging = {};

function DialogTagging.buildTagGroup(photo, tags, propertyTable, exportParams)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildTagGroup(photo, tags, propertyTable, exportParams)');
  local tagRows = {};

  KmnUtils.log(KmnUtils.LogDebug, prefs.tag_window_sort);

  if prefs.tag_window_sort == KmnUtils.SortProb then
    table.sort(tags, function(a, b)
      if (a.probability > b.probability) then
        return true;
      end
      return false;
    end
    );
  elseif prefs.tag_window_sort == KmnUtils.SortAlpha then
    table.sort(tags, function(a, b)
      if (a.tag < b.tag) then
        return true;
      end
      return false;
    end
    );
  end

  local existingPhotoKeywordString = photo:getFormattedMetadata('keywordTags');
  local existingPhotoKeywordNames = LUTILS.split(string.lower(existingPhotoKeywordString), ', ');
  for i=1, #tags do
    local tagName = tags[i]['tag'];
    local tagNameLower = string.lower(tagName);
    local keysByName = KwUtils.catKws[tagNameLower];
    local numKeysByName = keysByName ~= nil and #keysByName or 0;
    for tagNameIndex=0, numKeysByName do
      local tagNamePlusIndex = tagName .. "_" .. tagNameIndex
      local fontString = '<system>';
      local tagRow = {};
      local tt = '' -- tooltip
      if KwUtils.catKwPaths[tagNameLower] and KwUtils.catKwPaths[tagNameLower][tagNameIndex] == '' then
        tt = '(In the keyword root level)'
      elseif KwUtils.catKwPaths[lowerkey] ~= nil then
        tt = '(In ' .. KwUtils.catKwPaths[tagNameLower][tagNameIndex] .. ')'
      end

      propertyTable[tagNamePlusIndex] = false;
      -- Auto select tag if probability is above threshold
      if exportParams.global_auto_select_tags and (tags[i]['probability'] * 100) >= exportParams.global_auto_select_tags_p_min then
        propertyTable[tagNamePlusIndex] = true;
      end
    
      -- Auto select tag if it's already associated with the photo
      if LUTILS.inTable(string.lower(tagName), existingPhotoKeywordNames) then
        local keyword = KwUtils.catKws[string.lower(tagName)][tagNameIndex]
        if KwUtils.hasKeywordById(photo, keyword) then
          propertyTable[tagNamePlusIndex] = true
        else
          propertyTable[tagNamePlusIndex] = false
        end
      end

      tagRow[#tagRow + 1] = vf:checkbox {
        bind_to_object = propertyTable,
        title = tagName,
        font = fontString,
        checked_value = true,
        unchecked_value = false,
        value = bind(tagNamePlusIndex),
        tooltip = tt
      };

      if prefs.tag_window_show_probabilities then
        tagRow[#tagRow + 1] = vf:static_text {
          title = string.format('(%2.1f)', tags[i]['probability'] * 100),
        };
      end
    
      if prefs.tag_window_show_services then
        tagRow[#tagRow + 1] = vf:static_text {
          title = '[' .. tags[i]['service'] .. ']',
        };
      end

      tagRows[#tagRows + 1] = vf:row(tagRow);
    end
  end

  tagRows['title'] = 'Tags/Probabilities';

  return vf:group_box(tagRows);
end

function DialogTagging.buildColumn(context, exportParams, properties, photo, tags, processedTags)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildColumn(context, exportParams, properties, photo, tags, processedTags)');
  local contents = {};

  local photoTitle = photo:getFormattedMetadata 'title';
  if ( not photoTitle or #photoTitle == 0 ) then
    photoTitle = LrPathUtils.leafName( photo.path );
  end

  contents[#contents + 1] = vf:row {
    vf:static_text {
      title = photoTitle,
      font = '<system/bold>',
    }
  };

  contents[#contents + 1] = vf:row {
    vf:catalog_photo {
      photo = photo,
      width = prefs.tag_window_thumbnail_size,
      height = prefs.tag_window_thumbnail_size,
    }
  };
  
  contents[#contents + 1] = vf:row {
    vf:push_button {
      title = 'View Full Size Image',
      action = function (clickedview)
        LrDialogs.presentModalDialog({
          title = 'Review Image',
          contents = vf:catalog_photo {
            photo = photo,
            width = prefs.image_preview_window_width,
            height = prefs.image_preview_window_height,
          },
          cancelVerb = '< exclude >',
          actionVerb = 'Close Window',
        });
        end
    },
  };
  
  -- There are circumstances where no tags will be returned, be sure to avoid a null crash on tags.meta
  --    in case that happens
  if tags.meta ~= nil then 
    contents[#contents + 1] = vf:row {
      vf:group_box {
        title = 'API Settings',
        vf:row {
          vf:static_text {
            title = 'Model',
            font = '<system/bold>'
          },
          vf:static_text {
            title = tags.meta.tag.model
          }
        },
        vf:row {
          vf:static_text {
            title = 'Language',
            font = '<system/bold>'
          },
          vf:static_text {
            title = exportParams.clarifai_language
          },
        },
      }
    };
  end

  local imageProperties = LrBinding.makePropertyTable(context);
  properties[photo] = imageProperties;

  contents[#contents + 1] = DialogTagging.buildTagGroup(photo, processedTags, imageProperties, exportParams);

  local existingTagRows = {title = 'Existing Tags'};
  for _, keyword in ipairs(KmnUtils.sortedPhotoKeywords(photo)) do
    existingTagRows[#existingTagRows + 1] = vf:row {
      vf:static_text {
        title = keyword
      },
    };
  end
  contents[#contents +1] = vf:group_box(existingTagRows);

  contents['height'] = prefs.tag_window_height - 50;
  contents['horizontal_scroller'] = false;
  contents['vertical_scroller'] = true;
  return vf:column {
    vf:scrolled_view(contents)
  };
end

function DialogTagging.buildDialog(photosToTag, exportParams, mainProgress)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildDialog(photosToTag, exportParams, mainProgress)');
  KmnUtils.log(KmnUtils.LogTrace, table.tostring(photosToTag));
  LrFunctionContext.callWithContext('DialogTagger', (function(context)
    -- If don't have photos to tag (empty table), bail out with error
    -- Note #photosToTag will ALWAYS return 0, do the check the hard way
    local hasPhotosToTag = false;
    for photo,tags in pairs(photosToTag) do
      hasPhotosToTag = true;
      break;
    end
    if not hasPhotosToTag then
      LrDialogs.showError('Error processing photos, please check selected API preferences/tokens and try again');
      return
    end

    local properties = {};
    local columns = {};
    local processedTags = {};
    
    for photo,tags in pairs(photosToTag) do
      local photoProcessedTags = ClarifaiAPI.processTagsProbabilities(tags);
      processedTags[photo] = photoProcessedTags;
      columns[#columns + 1] = DialogTagging.buildColumn(context, exportParams, properties, photo, tags, photoProcessedTags);
    end

    local contents = vf:scrolled_view {
      width = prefs.tag_window_width,
      height = prefs.tag_window_height,
      horizontal_scroller = true,
      vertical_scroller = false,
      vf:row(columns)
    };

    local result = LrDialogs.presentModalDialog({
      title = 'Computer Vision Tagging',
      contents = contents,
      resizeable = true,
    });

    if result == 'ok' then
      local tagsByPhoto = {}
      local tagSelectionsByPhoto = {}

      for photo, tagValues in pairs(properties) do
        tagsByPhoto[photo] = {}
        tagSelectionsByPhoto[photo] = {}
        for _, taginfo in ipairs(processedTags[photo]) do
          tagsByPhoto[photo][taginfo.tag] = taginfo;
          tagSelectionsByPhoto[photo][taginfo.tag] = tagValues[taginfo.tag];
        end
      end
      Tagging.tagPhotos(tagsByPhoto, tagSelectionsByPhoto, mainProgress);
    end
  end));
end

return DialogTagging;
