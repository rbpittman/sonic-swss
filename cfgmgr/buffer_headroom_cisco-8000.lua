-- KEYS - profile name
-- ARGV[1] - port speed
-- ARGV[2] - cable length
-- ARGV[3] - port mtu
-- ARGV[4] - gearbox delay
-- ARGV[5] - lane count of the ports on which the profile will be applied

local port_speed_mbps = tonumber(ARGV[1])
local cable_length = tonumber(string.sub(ARGV[2], 1, -2))

-- Convert expected traffic load to worst case frame size
local buffer_size = 384
local xoff_value = 1234 * buffer_size
local frame_sizes = {128, 2048}
local grouped_frame_size = 0
for k, fs in pairs(frame_sizes) do
   grouped_frame_size = grouped_frame_size + fs
end

local line_rate_bps = port_speed_mbps * 1000000
local inter_frame_gap = 20
local max_grouped_frame_rate = line_rate_bps / (grouped_frame_size + (inter_frame_gap * #frame_sizes)) / 8
local max_buffer_rate = 0
for k, fs in pairs(frame_sizes) do
   local num_buffers = math.ceil(fs / buffer_size)
   max_buffer_rate = max_buffer_rate + (num_buffers * max_grouped_frame_rate)
end

local buffer_rate_padding_percent = 7.5
local final_buffer_rate = max_buffer_rate * (1 + (buffer_rate_padding_percent / 100))

-- Calculate buffer cable density
local speed_of_light = 299792458
local fiber_refractive_index = 1.467
local speed_of_light_in_fiber = speed_of_light / fiber_refractive_index
local buffers_per_meter = final_buffer_rate / speed_of_light_in_fiber
local hr_per_meter = 2 * buffers_per_meter

-- Calculate HR from cable length and base values
local constant_padding = 100
local min_hr_buffs_100G = 130
local scalar = port_speed_mbps / 100000
local hr_buffs = math.ceil((scalar * min_hr_buffs_100G) + (cable_length * hr_per_meter) + constant_padding)
local hr_bytes = buffer_size * hr_buffs

local ret = {}
table.insert(ret, "xon:0")
table.insert(ret, "size:0")
table.insert(ret, "xoff:" .. hr_bytes)
return ret
