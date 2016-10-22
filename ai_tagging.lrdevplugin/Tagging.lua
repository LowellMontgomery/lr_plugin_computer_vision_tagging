--[[----------------------------------------------------------------------------

Tagging.lua
Various tagging functionality / features

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

local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local KmnUtils = require 'KmnUtils'

Tagging = {}

function Tagging.tagPhotos(tagsByPhoto, tagSelectionsByPhoto, parentProgress)
  KmnUtils.log(KmnUtils.LogTrace, 'Tagging.tagPhotos(tagsByPhoto, tagSelectionsByPhoto, parentProgress)');
  KmnUtils.log(KmnUtils.LogTrace, table.tostring(tagsByPhoto));
  KmnUtils.log(KmnUtils.LogTrace, table.tostring(tagSelectionsByPhoto));

  local taggingProgress = LrProgressScope({ title = 'Tagging photo(s)', parent = parentProgress });
  local numPhotosToProcess = 0;
  local photosProcessed = 0;
  
  -- For some reason #tagsByPhoto doesn't work, count the total the hard way
  for _, __ in pairs(tagsByPhoto) do
    numPhotosToProcess = numPhotosToProcess + 1;
  end
  
  KmnUtils.log(KmnUtils.LogDebug, '# images to tag: ' .. numPhotosToProcess);
  
  local catalog = LrApplication.activeCatalog();
  local catalogKeywords = catalog:getKeywords();
  local newKeywords = {};
  
  for photo, tags in pairs(tagsByPhoto) do
    if taggingProgress:isCanceled() then
      break;
    end
    
    taggingProgress:setPortionComplete( photosProcessed, numPhotosToProcess );
    parentProgress:setCaption('Tagging ' .. photo:getFormattedMetadata( 'fileName' ));
    
    KmnUtils.log(KmnUtils.LogDebug, 'Tagging ' .. photo:getFormattedMetadata( 'fileName' ));
    
    for tag, taginfo in pairs(tags) do
      if taggingProgress:isCanceled() then
        break;
      end
      
      catalog:withWriteAccessDo('writePhotosKeywords', function(context)
        if tagSelectionsByPhoto[photo][taginfo.tag] ~= KmnUtils.photoHasKeyword(photo, taginfo.tag) then
          local keyword = catalog:createKeyword(taginfo.tag, {}, false, nil, true);
          if keyword == false then -- This keyword was created in the current withWriteAccessDo block, so we can't get by using `returnExisting`.
            keyword = newKeywords[taginfo.tag];
          else
            newKeywords[taginfo.tag] = keyword;
          end
          
          if tagSelectionsByPhoto[photo][taginfo.tag] then
            photo:addKeyword(keyword);
          else
            photo:removeKeyword(keyword);
          end
        end
      end);
    end
    photosProcessed = photosProcessed + 1;
  end
  taggingProgress:done();
end

return Tagging;
