--[[----------------------------------------------------------------------------

ClarifaiAPI.lua
Clarifai API implementation in pure lua

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

local LrDialogs = import 'LrDialogs'
local LrHttp = import 'LrHttp'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrRecursionGuard = import 'LrRecursionGuard'
local JSON = require 'JSON'
local KmnUtils = require 'KmnUtils'

local tokenAPIURL = 'https://api.clarifai.com/v1/token/'
local infoAPIURL = 'https://api.clarifai.com/v1/info/'
local usageAPIURL = 'https://api.clarifai.com/v1/usage/'
local tagAPIURL   = 'https://api.clarifai.com/v1/tag/'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN.id)

ClarifaiAPI = {}

function ClarifaiAPI.isTokenValid()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.isTokenValid()');
  if prefs.clarifai_accesstoken ~= nil and prefs.clarifai_accesstoken ~= '' then
    return true;
  end
  
  return false;
end

function ClarifaiAPI.isSecretValid()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.isSecretValid()');
  if prefs.clarifai_clientsecret ~= nil and prefs.clarifai_clientsecret ~= '' then
    return true;
  end
  
  return false;
end
  
function ClarifaiAPI.isClientIdValid()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.isClientIdValid()');
  if prefs.clarifai_clientid ~= nil and prefs.clarifai_clientid ~= '' then
    return true;
  end
  
  return false;
end

function ClarifaiAPI.getTokenUnsafe()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.getTokenUnsafe()');
  if not ClarifaiAPI.isClientIdValid() or not ClarifaiAPI.isSecretValid() then
    return
  end

  local headers = {
    { field = 'Content-Type', value = 'application/x-www-form-urlencoded' },
  };

  local data = 'grant_type=client_credentials&client_id=' .. prefs.clarifai_clientid .. '&client_secret=' .. prefs.clarifai_clientsecret;
  local body, reshdrs = LrHttp.post(tokenAPIURL, data, headers);

  KmnUtils.log(KmnUtils.LogInfo, table.tostring(reshdrs));
  KmnUtils.log(KmnUtils.LogInfo, body);

  if reshdrs.status == 401
    --and (reshdrs.status_code == 'TOKEN_APP_INVALID' or reshdrs.status_code == 'TOKEN_INVALID' or reshdrs.status_code == 'TOKEN_NONE' or reshdrs.status_code == 'TOKEN_NO_SCOPE')
  then
    LrDialogs.showError('Bad Clarifai Client ID or Client Secret. Please check your settings and try again');
    return
  end

  local json = JSON:decode(body);
  prefs.clarifai_accesstoken = json.access_token;
end

-- Main methods API consumers should call (everything is wrapped in tasks as appropriate)
function ClarifaiAPI.getToken()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.getToken()');
  LrTasks.startAsyncTask(function()
    ClarifaiAPI.getTokenUnsafe();
  end, 'ClarifaiAPI.getToken');
end

function ClarifaiAPI.getInfo()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.getInfo()');
  -- Ensure token is valid before running an operation
  if not ClarifaiAPI.isTokenValid() then
    ClarifaiAPI.getTokenUnsafe();
  end
  
  -- If token still isn't valid, return empty table
  if not ClarifaiAPI.isTokenValid() then
    return {};
  end

  local headers = {
    { field = 'Authorization', value = 'Bearer ' .. prefs.clarifai_accesstoken }, 
  }
  
  local body, reshdrs = LrHttp.get(infoAPIURL, headers);
  
  KmnUtils.log(KmnUtils.LogInfo, table.tostring(reshdrs));
  KmnUtils.log(KmnUtils.LogInfo, body);

  if reshdrs.status == 401 then
    ClarifaiAPI.getTokenUnsafe();
    return LrRecursionGuard:performWithGuard(ClarifaiAPI.getInfo());
  end
  
  return JSON:decode(body);
end

function ClarifaiAPI.getUsage()
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.getUsage()');
  -- Make sure token is valid before running any operations
  if not ClarifaiAPI.isTokenValid() then
    ClarifaiAPI.getTokenUnsafe();
  end
  
  -- If token is still invalid, return empty table
  if not ClarifaiAPI.isTokenValid() then
    return {};
  end

  local headers = {
    { field = 'Authorization', value = 'Bearer ' .. prefs.clarifai_accesstoken }, 
  }
  
  local body, reshdrs = LrHttp.get(usageAPIURL, headers);
  
  KmnUtils.log(KmnUtils.LogInfo, table.tostring(reshdrs));
  KmnUtils.log(KmnUtils.LogInfo, body);

  if reshdrs.status == 401 then
    ClarifaiAPI.getTokenUnsafe();
    return LrRecursionGuard:performWithGuard(ClarifaiAPI.getUsage());
  end
  
  return JSON:decode(body);
end

function ClarifaiAPI.getTags(photoPath, model, language)
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.getTags(photoPath, model, language)');
  if not ClarifaiAPI.isTokenValid() then
    ClarifaiAPI.getTokenUnsafe();
  end
  
  -- If token still isn't valid, return empty table
  if not ClarifaiAPI.isTokenValid() then
    return {};
  end
  
  local fileName = LrPathUtils.leafName(photoPath);

  local headers = {
    { field = 'Authorization', value = 'Bearer ' .. prefs.clarifai_accesstoken },
  };
  
  local mimeChunks = {
    { name = 'model', value = model },
    { name = 'language', value = language },
    { name = 'encoded_data', fileName = fileName, filePath = photoPath, contentType = 'application/octet-stream' };
  };

  local body, reshdrs = LrHttp.postMultipart(tagAPIURL, mimeChunks, headers);
  
  if reshdrs.status == 401 then
    ClarifaiAPI.getTokenUnsafe();
    return LrRecursionGuard:performWithGuard(ClarifaiAPI.getTags(photoPath, model, language));
  end

  return JSON:decode(body);
end

function ClarifaiAPI.processTagsProbibilities(response)
  KmnUtils.log(KmnUtils.LogTrace, 'ClarifaiAPI.processTagsProbibilities(response)');
  -- Don't crash if we receive an empty response
  -- #response will always return 0, do the check the hard way
  local hasResponseValues = false;
  for _, tag in pairs(response) do
    hasResponseValues = true;
    break;
  end
  if not hasResponseValues then
    return {};
  end
  
  local processedTagsProbabilities = {}
  for i, tag in ipairs(response['results'][1]['result']['tag']['classes']) do
    processedTagsProbabilities[#processedTagsProbabilities + 1] = { tag = tag, probability = response['results'][1]['result']['tag']['probs'][i], service = KmnUtils.SrvClarifai };
  end
  
  return processedTagsProbabilities;
end

return ClarifaiAPI;
