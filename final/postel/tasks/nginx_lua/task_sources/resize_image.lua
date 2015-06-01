local function return_not_found(msg)
    ngx.status = ngx.HTTP_NOT_FOUND
    if msg then
        ngx.header["Content-Type"] = "text/plain"
        ngx.header["X-Message"] = msg
        ngx.say(msg)
    end
    ngx.exit(0)
end

local libcurl = require "libcurl"
local curl = libcurl.easy_init()

function http_get(url)
    curl:setopt(libcurl.OPT_URL, url)
    local t = {}
    curl:setopt(libcurl.OPT_WRITEFUNCTION, function (param, buf)
        table.insert(t, buf)
        return #buf
    end)
    curl:setopt(libcurl.OPT_NOPROGRESS, 0)
    assert(curl:perform())
    return table.concat(t)
end

image_scales = {xsmall = ngx.var.scale_xsmall, small = ngx.var.scale_small, medium = ngx.var.scale_medium, large = ngx.var.scale_large, xlarge = ngx.var.scale_xlarge}

local filename, size, dest_filename = ngx.var.resize_filename, ngx.var.resize_size, ngx.var.resize_dest_filename
if not size then
    return_not_found()
end
if not image_scales[size] then
    return_not_found('Unexpected image scale')
end

local dest_dir = dest_filename:match("(.*/)")
os.execute("mkdir -p " .. dest_dir)

local magick = require("imagick")
if pcall(function() magick.thumb(filename, image_scales[size], dest_filename) end) then
    ngx.exec("@after_resize")
else
    return_not_found('File not found')
end
