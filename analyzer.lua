-- Lua High-Performance Log Analyzer
local log_file_path = arg[1] or "sample_access.log"

print("================================================================")
print("                 LUA HTTP LOG ANALYZER                          ")
print("================================================================")
print("Target Log: " .. log_file_path .. "\n")

local file = io.open(log_file_path, "r")
if not file then
    error("Cannot open log file: " .. log_file_path)
end

local total_requests = 0
local total_bytes = 0
local status_counts = {}
local ip_counts = {}
local url_counts = {}

-- Combined log format pattern: IP ... "METHOD URL ..." STATUS BYTES
local pattern = '^(%S+)%s+.-%s+%b[]%s+"(%S+)%s+(%S+)%s+.-"%s+(%d+)%s+(%d+)'

for line in file:lines() do
    local ip, method, url, status, bytes = line:match(pattern)
    if ip and url and status then
        total_requests = total_requests + 1
        bytes = tonumber(bytes) or 0
        total_bytes = total_bytes + bytes
        status = tonumber(status)

        status_counts[status] = (status_counts[status] or 0) + 1
        ip_counts[ip] = (ip_counts[ip] or 0) + 1
        url_counts[url] = (url_counts[url] or 0) + 1
    end
end
file:close()

local function get_top(tbl, limit)
    local sorted = {}
    for k, v in pairs(tbl) do
        table.insert(sorted, { key = k, count = v })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    local res = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(res, sorted[i])
    end
    return res
end

print(string.format("Total Requests Analyzed: %d", total_requests))
print(string.format("Total Transferred Bytes: %d bytes (%.2f KB)", total_bytes, total_bytes / 1024))
print("----------------------------------------------------------------")

print("\n[ HTTP STATUS CODES ]")
for status, count in pairs(status_counts) do
    local pct = (count / total_requests) * 100.0
    print(string.format("  HTTP %d : %4d requests (%5.1f%%)", status, count, pct))
end

print("\n[ TOP REQUESTED ENDPOINTS ]")
for i, item in ipairs(get_top(url_counts, 5)) do
    print(string.format("  %d. %-32s (%d hits)", i, item.key, item.count))
end

print("\n[ TOP VISITOR IPs ]")
for i, item in ipairs(get_top(ip_counts, 5)) do
    print(string.format("  %d. %-18s (%d requests)", i, item.key, item.count))
end

print("\n================================================================")
