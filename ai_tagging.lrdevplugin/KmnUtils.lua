--[[----------------------------------------------------------------------------

KmnUtils.lua
Various utility functions

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

local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local PlugInfo = require 'Info'

-- Setup useful bits that are needed elsewhere
local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)
local logger = LrLogger(PlugInfo.LrToolkitIdentifier);

-- Functions / additions for dumping tables to strings
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


-- Main KmN Utils definitions

KmnUtils = {}

KmnUtils.SortProb = 'prob';
KmnUtils.SortAlpha = 'alpha';

KmnUtils.SrvClarifai = 'clarifai';

KmnUtils.LogTrace = 6;
KmnUtils.LogDebug = 5;
KmnUtils.LogInfo = 4;
KmnUtils.LogWarn = 3;
KmnUtils.LogError = 2;
KmnUtils.LogFatal = 1;
KmnUtils.LogDisabled = -1;

function KmnUtils.log(level, value)
  -- There is a chance prefs will be null or log_level will be null; don't crash in that circumstance
  if prefs == nil or prefs.log_level == nil then
    return
  end
  
  -- Don't log if it's not turned on OR the log level in preferences isn't set high enough
  if level > prefs.log_level then
    return;
  end

  if level == KmnUtils.LogFatal then
    logger:fatal(value);
  elseif level == KmnUtils.LogError then
    logger:error(value)
  elseif level == KmnUtils.LogWarn then
    logger:warn(value)
  elseif level == KmnUtils.LogInfo then
    logger:info(value)
  elseif level == KmnUtils.LogDebug then
    logger:debug(value)
  else
    logger:trace(value)
  end
end

function KmnUtils.enableDisableLogging() 
  if prefs ~= nil and prefs.log_level ~= nil and prefs.log_level > 0 then
    logger:enable( 'logfile' );
    KmnUtils.log(KmnUtils.LogInfo, 'Debug log enabled');
  else
    logger.disable();
  end
end

function KmnUtils.photoHasKeyword(photo, keyword)
  KmnUtils.log(KmnUtils.LogTrace, 'KmnUtils.photoHasKeyword(photo, keyword)');
  local keywords = photo:getRawMetadata('keywords');
  
  for _, k in ipairs(keywords) do
    if k:getName() == keyword then
      return true
    end
  end  
  
  return false;
end

return KmnUtils;
