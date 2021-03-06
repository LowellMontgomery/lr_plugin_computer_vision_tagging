--[[----------------------------------------------------------------------------

LUTILS.lua
Utility functions for common Lua tasks. This is a bundle intended to provide
utility functions. Since it's for use in Lightroom plugins, it uses Lua 5.1.x
This bundle may grow over time, but is intended to remain limited in scope to
avoid including this file from causing undue bloat. 

--------------------------------------------------------------------------------

    Copyright 2016 Lowell ("LoweMo" / "LoMo") Montgomery
    https://lowemo.photo
    Latest version: https://lowemo.photo/lightroom-lua-utils

    This file is used in a few Lightroom plugins.

    This code is released under a Creative Commons CC-BY "Attribution" License:
    http://creativecommons.org/licenses/by/3.0/deed.en_US

    This bundle may be used for any purpose, provided that the copyright notice
    and web-page links, above, as well as the 'AUTHOR_NOTE' string, below are
    maintained. Enjoy.
------------------------------------------------------------------------------]]

local LUTILS = {}

LUTILS.VERSION = 20161202.03 -- version history at end of file
LUTILS.AUTHOR_NOTE = "LUTILS.lua--Lua utility functions by Lowell Montgomery (https://lowemo.photo/lightroom-lua-utils) version: " .. LUTILS.VERSION

-- The following provides an 80 character-width attribution text that can be inserted for display
-- in a plugin derived using these helper functions.
LUTILS.Attribution = "This plugin uses LUTILS, Lua utilities, © 2016 by Lowell Montgomery\n (https://lowemo.photo/lightroom-lua-utils) version: " .. LUTILS.VERSION .. "\n\nThis code is released under a Creative Commons CC-BY “Attribution” License:\n http://creativecommons.org/licenses/by/3.0/deed.en_US"

-- Check simple table for a given value's presence
function LUTILS.inTable (val, t)
    if type(t) ~= "table" then
        return false
    else
        for i, tval in pairs(t) do
            if val == tval then return true end
        end
    end
    return false;
end

-- Given a string and delimiter (e.g. ', '), break the string into parts and return as table
-- This works like PHP's explode() function.
function LUTILS.split(s, delim)
    if (delim == '') then return false end
    local pos = 0
    local t = {}
    -- For each delimiter found, add to return table
    for st, sp in function() return string.find(s, delim, pos, true) end do
        -- Get chars to next delimiter and insert in return table
        t[#t + 1] = string.sub(s, pos, st - 1)
        -- Move past the delimiter
       pos = sp + 1
    end
   -- Get chars after last delimiter and insert in return table
    t[#t + 1] = string.sub(s, pos)

    return t;
end

-- Merge two tables (like PHP array_merge())
function LUTILS.tableMerge(table1, table2)    
    for i=1,#table2 do
        table1[#table1 + 1] = table2[i]
    end
    return table1;
end

-- Basic trim functionality to remove whitespace from either end of a string
function LUTILS.trim(s)
    if s == nil then return nil end
    return string.gsub(s, '^%s*(.-)%s*$', '%1');
end

--Given a table, tbl, with keys (normally strings) that may include much more
-- data than we need, and simple array of keys that may exist in tbl, return a new
-- table, with only the key:value pairs corresponding to the 'keys' array.
-- NOTE: This function does NOT contain (e.g. string.lower) case conversion;
-- It assumes that is already done and/or there are cases where this is not wanted.
function LUTILS.trimTableToKeys (tbl, keys)
    local newTable = {};
    for _,k in pairs(keys) do
        newTable[k] = tbl[k] ~= nil and tbl[k] or nil;
    end
    return newTable;
end

--Wait for a global variable that may not have been initialized yet. If it is nil, wait.
-- Times out after 'timeout' seconds (or 30s, if only one argument is passed)
-- Returns the number of seconds which were waited (for debug/monitoring purposes) or false
-- if the timeout was reached and the variable name still didn't exist.
function LUTILS.waitForGlobal(globalName, timeout)
    local sleepTimer = 0;
    local LrTasks = import 'LrTasks';
    local timeout = (timeout ~= nil) and timeout or 30;
    while (_G[globalName] == nil) and (sleepTimer < timeout) do
        LrTasks.sleep(1);
        sleepTimer = sleepTimer + 1;
    end
    return _G[globalName] ~= nil and sleepTimer or false
end

return LUTILS;

-- 20161101.01 Initial pre-release version
-- 20161121.02 2nd Pre-release version; only minor changes.
-- 20161202.03 3rd pre-release version. Added new functions LUTILS.trimTableToKeys() and LUTILS.waitForGlobal()
