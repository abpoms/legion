-- Copyright 2015 Stanford University
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- runs-with:
-- [
--   ["pennant.tests/sedovsmall/sedovsmall.pnt",
--    "-npieces", "1", "-compact", "0"],
--   ["pennant.tests/sedovsmall/sedovsmall.pnt",
--    "-npieces", "2", "-compact", "0",
--    "-absolute", "1e-6", "-relative", "1e-6", "-relative_absolute", "1e-9"],
--   ["pennant.tests/sedov/sedov.pnt", "-npieces", "1", "-compact", "0",
--    "-absolute", "2e-6", "-relative", "1e-8", "-relative_absolute", "1e-10"],
--   ["pennant.tests/sedov/sedov.pnt", "-npieces", "3", "-compact", "0",
--    "-absolute", "2e-6", "-relative", "1e-8", "-relative_absolute", "1e-10"],
--   ["pennant.tests/leblanc/leblanc.pnt", "-npieces", "1", "-compact", "0"],
--   ["pennant.tests/leblanc/leblanc.pnt", "-npieces", "2", "-compact", "0"]
-- ]

-- Inspired by https://github.com/losalamos/PENNANT

-- (terra() c.printf("Compiling C++ module (t=%.1f)...\n", c.legion_get_current_time_in_micros()/1.e6) end)()

import "regent"

-- Compile and link pennant.cc
local cpennant
do
  local root_dir = arg[0]:match(".*/") or "./"
  local runtime_dir = root_dir .. "../../runtime"
  local pennant_cc = root_dir .. "pennant.cc"
  local pennant_so = os.tmpname() .. ".so" -- root_dir .. "pennant.so"
  local cxx = os.getenv('CXX') or 'c++'

  local cxx_flags = "-O2 -std=c++0x -Wall -Werror"
  if os.execute('test "$(uname)" = Darwin') == 0 then
    cxx_flags =
      (cxx_flags ..
         " -dynamiclib -single_module -undefined dynamic_lookup -fPIC")
  else
    cxx_flags = cxx_flags .. " -shared -fPIC"
  end

  local cmd = (cxx .. " " .. cxx_flags .. " -I " .. runtime_dir .. " " ..
                 pennant_cc .. " -o " .. pennant_so)
  if os.execute(cmd) ~= 0 then
    print("Error: failed to compile " .. pennant_cc)
    assert(false)
  end
  terralib.linklibrary(pennant_so)
  cpennant = terralib.includec("pennant.h", {"-I", root_dir, "-I", runtime_dir})
end

task toplevel()
end
regentlib.start(toplevel)
