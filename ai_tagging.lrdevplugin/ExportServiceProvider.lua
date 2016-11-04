--[[----------------------------------------------------------------------------

ExportServiceProvider.lua
Define the export process for submitting photos to APIs

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
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDialogs = import 'LrDialogs'
local KmnUtils = require 'KmnUtils'
local ClarifaiAPI = require 'ClarifaiAPI'
local DialogTagging = require 'DialogTagging'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

local exportServiceProvider = {}
exportServiceProvider.hideSections = { 'fileNaming', 'exportLocation', 'fileSettings', 'imageSettings', 'video' }
exportServiceProvider.hidePrintResolution = true
exportServiceProvider.canExportToTemporaryLocation = true
exportServiceProvider.canExportVideo = false
exportServiceProvider.exportPresetFields = {
  { key = 'global_save_sidecar', default = true },
  { key = 'global_save_sidecar_unique', default = false },
  { key = 'global_size_mpx', default = 2 },
  { key = 'global_jpeg_quality', default = 50 },
  { key = 'global_auto_select_tags', default = false },
  { key = 'global_auto_select_tags_p_min', default = 85 },
  { key = 'global_auto_save_tags', default = false },
  { key = 'global_auto_save_tags_p_min', default = 95 },
  { key = 'clarifai_model', default = 'general-v1.3' },
  { key = 'clarifai_language', default = 'en' },
  { key = 'enable_api_clarifai', default = true },
}

function exportServiceProvider.sectionsForTopOfDialog( vf, propertyTable )
  KmnUtils.log(KmnUtils.LogTrace, 'exportServiceProvider.sectionsForTopOfDialog(vf, propertyTable)');
  local bind = LrView.bind;
  
  return {
    {
      title = LOC '$$$/ComputerVisionTagging/ExportDialog/Global=Global Settings',
      vf:row {
        vf:static_text {
          title = 'Select which APIs and services will be used by the plugin',
        },
      },
      vf:row {
        vf:checkbox {
          title = 'Clarifai',
          enabled = false, -- TODO: Re-enable field when more APIs are implemented
          checked_value = true,
          unchecked_value = false,
          value = bind 'enable_api_clarifai',
        },
      },
    },
    {
      title = 'Image Quality',
      vf:row {
        vf:static_text {
          title = 'Size (Mpx)',
          tooltip = 'Size of the image to send in megapixels. Specify \'0\' for no resizing.',
        },
        vf:edit_field {
          value = bind 'global_size_mpx',
          width_in_digits = 3,
          tooltip = 'Size of the image to send in megapixels. Specify \'0\' for no resizing.',
        },
      },
      vf:row {
        vf:static_text {
          title = 'JPEG Quality',
          tooltip = 'Quality of the JPEG to send'
        },
        vf:slider {
          value = bind 'global_jpeg_quality',
          min = 15,
          max = 100,
          integral = true,
          tooltip = 'Quality of the JPEG to send'
        },
        vf:edit_field {
          value = bind 'global_jpeg_quality',
          tooltip = 'Quality of the JPEG to send',
          fill_horizonal = 1,
          width_in_chars = 4,
          min = 15,
          max = 100,
          increment = 1,
          precision = 0,
        }
      },
    },
    {
      title = 'Tags',
      vf:row {
        vf:checkbox {
          title = 'Auto-Select tags',
          checked_value = true,
          unchecked_value = false,
          value = bind 'global_auto_select_tags',
        },
      },
      vf:row {
        vf:static_text {
          title = 'Auto select minimum probability (inclusive)',
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-selected'
        },
        vf:slider {
          value = bind 'global_auto_select_tags_p_min',
          min = 0,
          max = 100,
          integral = true,
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-selected'
        },
        vf:edit_field {
          value = bind 'global_auto_select_tags_p_min',
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-selected',
          fill_horizonal = 1,
          width_in_chars = 4,
          min = 0,
          max = 100,
          increment = 1,
          precision = 0,
        }
      },
      vf:row {
        vf:checkbox {
          title = 'Auto save tags',
          tooltip = 'Automatically save tags (no dialog) with minimum probability',
          value = bind 'global_auto_save_tags',
          checked_value = true,
          unchecked_value = false,
        },
      },
      vf:row {
        vf:static_text {
          title = 'Auto save minimum probability (inclusive)',
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-saved'
        },
        vf:slider {
          value = bind 'global_auto_save_tags_p_min',
          min = 1,
          max = 100,
          integral = true,
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-saved'
        },
        vf:edit_field {
          value = bind 'global_auto_save_tags_p_min',
          tooltip = 'The minimum probability (inclusive) used to determine if a tag is auto-saved',
          fill_horizonal = 1,
          width_in_chars = 4,
          min = 1,
          max = 100,
          increment = 1,
          precision = 0,
        }
      },
    },
    {
      title = 'Side Car files',
      vf:row {
        vf:checkbox {
          title = 'Save sidecar json files',
          tooltip = 'Save json responses from APIs as sidecar files',
          value = bind 'global_save_sidecar',
          checked_value = true,
          unchecked_value = false,
        },
      },
      vf:row {
        vf:checkbox {
          title = 'Save sidecars with timestamped names',
          tooltip = 'Use mm/dd/yyyy.HHMMSS for uniqueness of sidecar names',
          value = bind 'global_save_sidecar_unique',
          checked_value = true,
          unchecked_value = false,
        },
      },
    },
    {
      title = LOC "$$$/ComputerVisionTagging/ExportDialog/Clarifai=Clarifai Settings",
      vf:row {
        vf:static_text {
          title = 'Model',
          tooltip = 'The Clarifai model to use for submissions'
        },
        vf:popup_menu {
          value = bind 'clarifai_model',
          tooltip = 'The Clarifai model to use for submissions',
          items = {
            { value = 'general-v1.3', title = 'General' },
            { value = 'nsfw-v1.0', title = 'NSFW' },
            { value = 'weddings-v1.0', title = 'Weddings' },
            { value = 'travel-v1.0', title = 'Travel' },
            { value = 'food-items-v1.0', title = 'Food Items' },
          },
        },
      },
      vf:row {
        vf:static_text {
          title = 'Language',
          tooltip = 'The language to use for Clarifai responses',
        },
        vf:popup_menu {
          value = bind 'clarifai_language',
          tooltip = 'The language to use for Clarifai responses',
          items = {
            { value = 'en', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/English=English (en)' },
            { value = 'zh', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/ChineseSimplified=Chinese Simplified (zh)' },
            { value = 'it', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Italian=Italian (it)' },
            { value = 'ar', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Arabic=Arabic (ar)' },
            { value = 'es', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Spanish=Spanish (es)' },
            { value = 'ru', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Russian=Russian (ru)' },
            { value = 'nl', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Dutch=Dutch (nl)' },
            { value = 'pt', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Portuguese=Portuguese (pt)' },
            { value = 'no', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Norwegian=Norwegian (no)' },
            { value = 'tr', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Turkish=Turkish (tr)' },
            { value = 'pa', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Punjabi=Punjabi (pa)' },
            { value = 'pl', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Polish=Polish (pl)' },
            { value = 'fr', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/French=French (fr)' },
            { value = 'bn', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Bengali=Bengali (bn)' },
            { value = 'de', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/German=German (de)' },
            { value = 'da', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Danish=Danish (da)' },
            { value = 'hi', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Hindi=Hindi (hi)' },
            { value = 'fi', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Finnish=Finnish (fi)' },
            { value = 'hu', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Hungarian=Hungarian (hu)' },
            { value = 'ja', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Japanese=Japanese (ja)' },
            { value = 'zh-TW', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/ChineseTraditional=Chinese Traditional (zh-TW)' },
            { value = 'ko', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Korean=Korean (ko)' },
            { value = 'sv', title = LOC '$$$/ComputerVisionTagging/ExportDialog/ClarifaiLanguage/Swedish=Swedish (sv)' },
          },
        },
      },
    }
  }
end

function exportServiceProvider.updateExportSettings( exportSettings )
  KmnUtils.log(KmnUtils.LogTrace, 'exportServiceProvider.updateExportSettings(exportSettings)');
  -- Ensure these files never get saved
  exportSettings.LR_export_destinationType = 'tempFolder';
  -- APIs use JPEGs, ensure sending the right type
  exportSettings.LR_format = 'JPEG';
  -- Ensure image is resized down (if necessary)
  exportSettings.LR_size_doConstrain = true;
  --LR_size_maxHeight / LR_size_maxWidth not necessary, use megapixel resize option built into LightRoom
  if exportSettings.global_size_mpx > 0 then
    exportSettings.LR_size_megapixels = exportSettings.global_size_mpx;
    exportSettings.LR_size_resizeType = 'megapixels';
  end
  -- Ensure image quality is set properly
  exportSettings.LR_jpeg_quality = exportSettings.global_jpeg_quality / 100.0;
  -- We don't want to scale an image up in size, override defaults
  exportSettings.LR_size_doNotEnlarge = true;
end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
  KmnUtils.log(KmnUtils.LogTrace, 'exportServiceProvider.processRenderedPhotos(functionContext, exportContext)');
  local exportSession = exportContext.exportSession;
  local exportParams = exportContext.propertyTable;
  
  local clarifai_model = exportParams.clarifai_model;
  local clarifai_language = exportParams.clarifai_language;
    
  local nPhotos = exportSession:countRenditions();
  
  local progressScope = exportContext:configureProgress {
            title = nPhotos > 1
                 and LOC( "$$$/ComputerVisionTagging/Upload/Progress=Processing ^1 photos", nPhotos )
                 or LOC "$$$/ComputerVisionTagging/Upload/Progress/One=Processing one photo",
          };
  
  local photosToTag = {};
  local failures = {};
  
  for _, rendition in exportContext:renditions{ stopIfCanceled = true } do
    local success, pathOrMessage = rendition:waitForRender()
    
    if progressScope:isCanceled() then break end
    
    if success then
      local filename = LrPathUtils.leafName( pathOrMessage );
      
      local success = false;
      local result = nil;
      if exportParams.enable_api_clarifai then
        result = ClarifaiAPI.getTags(pathOrMessage, exportParams.clarifai_model, exportParams.clarifai_language);
      end
      
      if result ~= nil then
        success = true;
        if exportParams.global_save_sidecar then
          local sidecarPath = LrPathUtils.replaceExtension(rendition.photo.path, 'clarifai.json');
          if exportParams.global_save_sidecar_unique then
            local uniqueExtension = os.date('%Y%m%d') .. '.' .. os.date('%H%M%S') .. '.json';
            KmnUtils.log(KmnUtils.LogTrace, uniqueExtension);
            sidecarPath = LrPathUtils.replaceExtension(sidecarPath, uniqueExtension);
          end
          local out = io.open(sidecarPath, 'w');
          io.output(out);
          io.write(table.tostring(result));
          io.close(out);
        end
      end
      
      if success then
        photosToTag[rendition.photo] = result;
      else
        table.insert( failures, filename );
      end
      
      -- When done with photo, delete temp file. There is a cleanup step that happens later,
      -- but this will help manage space in the event of a large upload.
      LrFileUtils.delete( pathOrMessage );
    end
  end
  
  if #failures > 0 then
    local message
    if #failures == 1 then
      message = LOC "$$$/ComputerVisionTagging/Upload/Errors/OneFileFailed=1 file failed to process correctly.";
    else
      message = LOC ( "$$$/ComputerVisionTagging/Upload/Errors/SomeFileFailed=^1 files failed to process correctly.", #failures );
    end
    LrDialogs.message( message, table.concat( failures, "\n" ) );
  else
    if exportParams.global_auto_save_tags then
      local tagsByPhoto = {};
      local tagSelectionsByPhoto = {};
    
      for photo, apiResult in pairs(photosToTag) do
        tagsByPhoto[photo] = {};
        local tagDetails = ClarifaiAPI.processTagsProbibilities(apiResult);
        for _, tag in ipairs(tagDetails) do
          tagsByPhoto[photo][tag.tag] = tag;
        end
      end
      
      for photo, tagValues in pairs(tagsByPhoto) do
        tagSelectionsByPhoto[photo] = {}
        for _, taginfo in pairs(tagValues) do
          tagSelectionsByPhoto[photo][taginfo.tag] = exportParams.global_auto_save_tags_p_min < taginfo.probability * 100;
        end
      end
      KmnUtils.log(KmnUtils.LogTrace, table.tostring(tagsByPhoto));
      KmnUtils.log(KmnUtils.LogTrace, table.tostring(tagSelectionsByPhoto));
      Tagging.tagPhotos(tagsByPhoto, tagSelectionsByPhoto, progressScope);
    else 
      DialogTagging.buildDialog(photosToTag, exportParams, progressScope);
    end
  end
end

return exportServiceProvider
