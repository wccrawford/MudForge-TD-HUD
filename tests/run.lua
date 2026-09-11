-- luajit tests/run.lua   (from the repo root; exit 1 on the first failure)
package.path = "lib/?.lua;" .. package.path
local files = { "countdown_test", "status_test", "effects_test", "slots_test" }   -- explicit list: stock Lua has no directory listing
for _, name in ipairs(files) do
  local ok, err = pcall(dofile, "tests/" .. name .. ".lua")
  if not ok then
    io.stderr:write("FAIL " .. name .. ": " .. tostring(err) .. "\n")
    os.exit(1)
  end
end
print("all tests passed")
