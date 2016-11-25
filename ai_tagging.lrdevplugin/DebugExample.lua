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

-- Enable debugging for plugin
local Require = require 'Require'.path ("../debugscript.lrdevplugin")
local Debug = require 'Debug'.init ()
require 'strict'

-- See debugscript.lrdevplugin/Debugging Toolkit.htm for general details on usage

-- See http://www.johnrellis.com/lightroom/debugging-toolkit.htm for what the additional debugging options you have are