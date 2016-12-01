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

local DialogTagging = {};
local properties = {};
local photoKeywordTables = {}; -- Store array of keywords for each photo
local photoKeywordLowerNamesTable = {}; -- Store array of keyword names for each photo
local allPhotoKeywordLowerNames = {}; -- Store collection of keyword names for all selected photos
local showStarMessage = {}; -- Array of booleans indexed by column number
local tagNamesLower = {}; -- Array of arrays of tagNames, indexed by column number

function DialogTagging.buildTagGroup(photo, colNum, tags, propertyTable, exportParams)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildTagGroup(photo, tags, propertyTable, exportParams)');
  local tagRows = {};
  showStarMessage[colNum] = false;

  -- KmnUtils.log(KmnUtils.LogDebug, prefs.tag_window_sort);

  if prefs.tag_window_sort == KmnUtils.SortProb then
    table.sort(tags, function(a, b)
      if (a.probability > b.probability) then
        return true;
      end
      return false;
    end);
  elseif prefs.tag_window_sort == KmnUtils.SortAlpha then
    table.sort(tags, function(a, b)
      if (a.tag < b.tag) then
        return true;
      end
      return false;
    end);
  end

  for i=1, #tags do
    local tagProperties = tags[i];
    local tagName = tagProperties['tag'];
    local tagNameLower = string.lower(tagName);
    local keysByName = _G.AllKeys[tagNameLower];
    local numKeysByName = keysByName ~= nil and #keysByName or 0;
    if numKeysByName == 0 then
      DialogTagging.addTagRow(photo, colNum, tagRows, tagProperties, 1, propertyTable, exportParams)
    else
      for j,numKeysByName in ipairs(keysByName) do
        DialogTagging.addTagRow(photo, colNum, tagRows, tagProperties, j, propertyTable, exportParams)
      end
    end   
  end

  local showProbs = prefs.tag_window_show_probabilities;
  local showServices = prefs.tag_window_show_services;
  tagRowsTitle = (showProbs == true) and 'Tags / Probabilities' or 'Tags';
  tagRowsTitle = (showServices == true) and tagRowsTitle .. ' / Services:' or tagRowsTitle .. ':';
  
  tagRows['title'] = tagRowsTitle;
  tagRows['font'] = '<system/bold>';
  
  -- Only show the * Note if we have at least one already-associated
  -- keyword which has a name corresponding to a "suggested tag" from the service.
  -- (I.e. the message is never shown if this is the first keywording done for the photo.)
  if (showStarMessage[colNum]) then
    local starMessage = "Existing keyword for photo;\nunchecking will REMOVE existing keyword.";
    tagRows[#tagRows + 1] = vf:row {
      -- spacing = vf:label_spacing(),
      vf:static_text {
        title = '*', -- Asterisk we add to "name" of previously-selected keyword/tags.
        font = '<system/bold>'
      },
      vf:static_text {
        title = starMessage,
        font = '<system>'
      }
    };
  end  

  return vf:group_box(tagRows);
end

-- Helper function to build a single checkbox row for a given keyword name.
  -- Called by DialogTagging.buildTagGroup since muliple keywords can share returned tag name.
function DialogTagging.addTagRow(photo, colNum, tagRows, tagProperties, tagNameIndex, propertyTable, exportParams)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.addTagRow(photo, colNum, tagRows, tagProperties, tagNameIndex, propertyTable, exportParams)');
  local tagName = tagProperties['tag'];
  local tagProbability = tagProperties['probability'] * 100;
  local tagNameLower = string.lower(tagName);
  local tagNamePlusIndex = tagName .. "_" .. tagNameIndex;
  local existingPhotoKeywordNames = photoKeywordLowerNamesTable[colNum];
  local fontString = '<system>';
  local tagRow = {};
  local tt = '' -- tooltip
  if _G.AllKeyPaths[tagNameLower] ~= nil then
    if prefs.tag_window_bold_existing_tags then
      fontString = '<system/bold>'
    end
    if _G.AllKeyPaths[tagNameLower][tagNameIndex] == '' then
      tt = '(In the keyword root level)'
    elseif _G.AllKeyPaths[tagNameLower][tagNameIndex] ~= nil then
      tt = '(In ' .. _G.AllKeyPaths[tagNameLower][tagNameIndex] .. ')'
    end
    -- This tag does not correspond to an existing keyword:
    else -- _G.AllKeyPaths[tagNameLower] == nil
      tt = "New keyword by the name “”" .. tagName .. "” will be created by selecting this tag."
  end

  propertyTable[tagNamePlusIndex] = false;
  -- Auto select tag if probability is above threshold,
  -- if the keyword exists in the Lr catalog, and if this behavior is configured:
  local autoSelect = exportParams.global_auto_select_tags
  local autoSelectThreshold = exportParams.global_auto_select_tags_p_min
  if (_G.AllKeyPaths[tagNameLower] ~= nil) and autoSelect and (tagProbability >= autoSelectThreshold) then
    propertyTable[tagNamePlusIndex] = true;
  end

  -- Auto select tag if it's already associated with the photo
  if LUTILS.inTable(tagNameLower, existingPhotoKeywordNames) then
    -- KmnUtils.log(KmnUtils.LogTrace, 'Getting keyword object for: ' .. tagNameLower .. "-" .. tagNameIndex);
    -- If there is only one keyword by the name, we can simply select the checkbox:
    if #_G.AllKeyPaths[tagNameLower] == 1 then
      propertyTable[tagNamePlusIndex] = true
      tagName = tagName .. "*";
      showStarMessage[colNum] = true;
    -- If there are more than one keyword objects with the name, actually examine the keyword object
    -- to correctly set the checkbox state:
    elseif #_G.AllKeyPaths[tagNameLower] > 1 then
      local keyword = _G.AllKeys[tagNameLower][tagNameIndex];
      if KwUtils.hasKeywordById(photo, keyword) then
        propertyTable[tagNamePlusIndex] = true
        tagName = tagName .. "*";
        showStarMessage[colNum] = true;
      else
        propertyTable[tagNamePlusIndex] = false
      end
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
      title = string.format('(%2.1f)', tagProbability),
    };
  end

  if prefs.tag_window_show_services then
    tagRow[#tagRow + 1] = vf:static_text {
      title = '[' .. tagProperties['service'] .. ']',
    };
  end

  tagRows[#tagRows + 1] = vf:row(tagRow);  
end

function DialogTagging.buildColumn(context, exportParams, photo, colNumber, tags, processedTags)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildColumn(context, exportParams, photo, tags, processedTags)');
  local contents = {};

  local photoTitle = photo:getFormattedMetadata 'title';
  if ( not photoTitle or #photoTitle == 0 ) then
    photoTitle = LrPathUtils.leafName( photo.path );
  end
  
  -- contents[#contents + 1] = spacing = f:label_spacing(8);

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
      height = prefs.tag_window_thumbnail_size
      -- mouse_down = function (clickedview)
      --   LrDialogs.presentModalDialog({
      --     title = 'Review Image',
      --     contents = vf:catalog_photo {
      --       photo = photo,
      --       width = prefs.image_preview_window_width,
      --       height = prefs.image_preview_window_height,
      --     },
      --     cancelVerb = '< exclude >',
      --     actionVerb = 'Close Window',
      --   });
      -- end
    }
  };
  
  local previewWidth = prefs.image_preview_window_width;
  local previewHeight = prefs.image_preview_window_height;
  local dimensions = previewWidth .. " x " .. previewHeight .. "px";
  local previewButtonTt = "Open larger preview (in window with configured dimensions of: " .. dimensions .. ")";
  
  contents[#contents + 1] = vf:row {
    spacing = vf:control_spacing(),
    vf:push_button {
      title = 'View Full Preview',
      tooltip = previewButtonTt,
      action = function (clickedview)
        LrDialogs.presentModalDialog({
          title = 'Review Image',
          contents = vf:catalog_photo {
            photo = photo,
            width = previewWidth,
            height = previewHeight,
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
    contents[#contents + 1] = vf:spacer { width = 1, height = 1};
    contents[#contents + 1] = vf:row {
      spacing = vf:label_spacing(),
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

  contents[#contents + 1] = vf:spacer { width = 1, height = 8};
  contents[#contents + 1] = DialogTagging.buildTagGroup(photo, colNumber, processedTags, imageProperties, exportParams);
  contents[#contents + 1] = vf:spacer { width = 1, height = 4};

  -- LIST OF EXISTING (OTHER) TAGS/KEYWORDS FOR THE PHOTO:
  -- getFormattedMetadata(keywordTags), provides a simple, pre-rendered alphabetical list of keyword names already on a photo.
  -- Split that into a table around ", " and we have the array of Keyword Names for the photo:
  local photoKeywordList = photo:getFormattedMetadata('keywordTags');
  local photoKeywordNames = LUTILS.split(photoKeywordList, ', ');

  local otherTags = {}
  for _, keyName in ipairs(photoKeywordNames) do
    if not LUTILS.inTable(string.lower(keyName), tagNamesLower[colNumber]) then
      otherTags[#otherTags + 1] = keyName;
    end
  end
  
  -- Only add the group if there is at least one other keyword to display
  if #otherTags > 0 then
    local existingTagRows = {title = 'Other Keywords for Image', font = '<system/bold>'};
    for _, keywordName in ipairs(otherTags) do
      existingTagRows[#existingTagRows + 1] = vf:row {
        vf:static_text {
          title = keywordName,
          font = '<system>'
        },
      };
    end
    contents[#contents +1] = vf:group_box(existingTagRows);
  end

  contents['height'] = prefs.tag_window_height - 50;
  contents['horizontal_scroller'] = false;
  contents['vertical_scroller'] = false;
  return vf:column {
    vf:scrolled_view(contents)
  };
end

function DialogTagging.buildDialog(photosToTag, exportParams, mainProgress)
  KmnUtils.log(KmnUtils.LogTrace, 'DialogTagging.buildDialog(photosToTag, exportParams, mainProgress)');
  -- KmnUtils.log(KmnUtils.LogTrace, table.tostring(photosToTag));

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
    
    local columns = {};
    -- local photoKeywordTables = {}; -- Store array of keywords for each photo
    -- local photoKeywordLowerNamesTable = {}; -- Store array of keyword names for each photo
    -- local allPhotoKeywordLowerNames = {}; -- Store collection of keyword names for all selected photos
    
    -- Gather all suggested photo tags (i.e. for all selected photos) in a simple array
    -- and call the processTagsProbabilities function to clean up the tags for subsequent functions
    local processedTags = {};
    local AllPhotoTagsLower = {};
    local colNum = 1;
    for photo,tags in pairs(photosToTag) do
      processedTags[photo], tagNamesLower[colNum] = ClarifaiAPI.processTagsProbabilities(tags);
      local photoKeywords = photo:getRawMetadata('keywords');
      local photoKeywordLowerNames = KwUtils.getKeywordNames(photoKeywords, true);
      photoKeywordTables[#photoKeywordTables + 1] = photoKeywords;
      photoKeywordLowerNamesTable[#photoKeywordLowerNamesTable + 1] = photoKeywordLowerNames;
      
      -- Add to array of all returned tags (for the current selection of photos)
      for _,tagInfo in ipairs(processedTags[photo]) do
        if not (LUTILS.inTable(string.lower(tagInfo.tag), AllPhotoTagsLower)) then
          AllPhotoTagsLower[#AllPhotoTagsLower + 1] = string.lower(tagInfo.tag);
        end
      end
      
      for _,keyNameLower in ipairs(photoKeywordLowerNames) do
        if not (LUTILS.inTable(keyNameLower, allPhotoKeywordLowerNames)) then
          allPhotoKeywordLowerNames[#allPhotoKeywordLowerNames + 1] = keyNameLower;
        end
      end
      colNum = colNum + 1;
    end
    
    -- KmnUtils.log(KmnUtils.LogTrace, "AllPhotoTagsLower");
    -- KmnUtils.log(KmnUtils.LogTrace, table.tostring(AllPhotoTagsLower));
    
    -- Before we trim down our lookup table for keywords and keyword paths, we should
    -- be sure the process of populating our global variables for these has completed.
    local sleepTimer = 0;
    local timeout = 30; -- If it doesn't complete within 30s more, something is wrong. 
    while ((_G.AllKeys == nil) and (sleepTimer < timeout)) do
        LrTasks.sleep(1);
        sleepTimer = sleepTimer + 1;
    end
    
    if sleepTimer < 30 then
      KmnUtils.log(KmnUtils.LogTrace, 'Global _G.AllKeys ready for use after ' .. sleepTimer .. ' seconds');
    else 
      KmnUtils.log(KmnUtils.LogTrace, 'Global _G.AllKeys non-existent after waiting ' .. sleepTimer .. ' seconds');
      LrDialogs.showError('Problems encountered processing catalog keywords. Timed out after ' .. sleepTimer .. ' seconds');
      return
    end
    
    -- Trim our lookup keyword and path lookup tables to include only what we need.
    -- After this _G.AllKeys and _G.AllKeyPaths will only include keywords and paths which
    -- correspond to the tags returned by the service
    for keyNameLower,_ in pairs(_G.AllKeys) do
      if not (LUTILS.inTable(keyNameLower, AllPhotoTagsLower)) then
        _G.AllKeys[keyNameLower] = nil;
        _G.AllKeyPaths[keyNameLower] = nil;
      end
    end

    -- KmnUtils.log(KmnUtils.LogTrace, "Catalog Keywords");
    -- KmnUtils.log(KmnUtils.LogTrace, table.tostring( _G.AllKeys ));
    -- KmnUtils.log(KmnUtils.LogTrace, "Catalog Keyword Paths");
    -- KmnUtils.log(KmnUtils.LogTrace, table.tostring( _G.AllKeyPaths ));

    local colNum = 1;
    for photo,tags in pairs(photosToTag) do
      columns[colNum] = DialogTagging.buildColumn(context, exportParams, photo, colNum, tags, processedTags[photo]);
      colNum = colNum + 1;
    end

    local contents = vf:scrolled_view {
      width = prefs.tag_window_width,
      height = prefs.tag_window_height,
      horizontal_scroller = true,
      vertical_scroller = true,
      vf:row(columns)
    };

    local result = LrDialogs.presentModalDialog({
      title = 'Computer Vision Tagging',
      contents = contents,
      resizeable = true,
    });
    
    -- KmnUtils.log(KmnUtils.LogTrace, "Properties table for Tagging Dialog");
    -- KmnUtils.log(KmnUtils.LogTrace, table.tostring(properties));

    if result == 'ok' then
      local tagsByPhoto = {}
      local tagSelectionsByPhoto = {}

      for photo, tagValues in pairs(properties) do
        tagsByPhoto[photo] = {}
        tagSelectionsByPhoto[photo] = {}
        for _, taginfo in ipairs(processedTags[photo]) do
          local tagName = taginfo.tag;
          tagsByPhoto[photo][tagName] = taginfo;
          -- Tag labels have an extra index from 1 to as many keywords have the name
          local tagIndex = 1;
          local tagNameLower = string.lower(tagName);
          tagSelectionsByPhoto[photo][tagName] = {}
          if _G.AllKeys[tagNameLower] ~= nil then
            -- There may be several keywords which share the same "tagName"
            -- Each of the keywords has its own checkbox indexed from 1
            for i,_ in ipairs(_G.AllKeys[tagNameLower]) do
              tagSelectionsByPhoto[photo][tagName][i] = tagValues[tagName .. "_" .. i];
            end
          else
            -- There is not yet a keyword by the name "tagName"
            tagSelectionsByPhoto[photo][tagName][1] = tagValues[tagName .. "_" .. 1];
          end
        end
      end
      Tagging.tagPhotos(tagsByPhoto, tagSelectionsByPhoto, mainProgress);
    end
  end))
end

return DialogTagging;
