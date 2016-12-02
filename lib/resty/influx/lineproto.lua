local _M = {}

local str_gsub = string.gsub
local str_find = string.find
local str_fmt  = string.format
local tbl_cat  = table.concat

_M.version = "0.2"

-- quoting routines based on
-- https://docs.influxdata.com/influxdb/v1.0/write_protocols/line_protocol_reference/

function _M.quote_field_value(value)
	value = str_gsub(value, '"', '\\"')

	return str_fmt('"%s"', value)
end

function _M.quote_field_key(value)
	value = str_gsub(value, ',', '\\,')
	value = str_gsub(value, '=', '\\=')
	value = str_gsub(value, ' ', '\\ ')

	return value
end

function _M.quote_tag_part(value)
	value = str_gsub(value, ',', '\\,')
	value = str_gsub(value, '=', '\\=')
	value = str_gsub(value, ' ', '\\ ')

	return value
end

function _M.quote_measurement(value)
	value = str_gsub(value, ',', '\\,')
	value = str_gsub(value, ' ', '\\ ')

	return value
end

function _M.build_tag_set(tags)
	local tag_set = {}

	for i = 1, #tags do
		local tag      = tags[i]
		local key, val = next(tag)

		key = _M.quote_tag_part(key)
		val = _M.quote_tag_part(val)

		tag_set[i] = str_fmt("%s=%s", key, val)
	end

	-- TODO sort tags by keys
	return tag_set
end

function _M.build_field_set(fields)
	local field_set = {}

	for i = 1, #fields do
		local field    = fields[i]
		local key, val = next(field)

		key = _M.quote_field_key(key)
		if type(val) == "string" and not str_find(val, '^%d+i$') then
			val = _M.quote_field_value(val)
		end

		field_set[i] = str_fmt("%s=%s", key, val)
	end

	return field_set
end

function _M.build_line_proto_stmt(influx)
	local measurement = influx._measurement
	local tag_set     = tbl_cat(influx._tag_set, ',')
	local field_set   = tbl_cat(influx._field_set, ',')
	local timestamp   = influx._stamp

	if (tag_set ~= '') then
		return str_fmt("%s,%s %s %s", measurement, tag_set, field_set, timestamp)
	else
		return str_fmt("%s %s %s", measurement, field_set, timestamp)
	end
end

return _M
