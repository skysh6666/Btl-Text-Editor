local Hex = {}

-- 大写十六进制字符集（同Java的 zzgw）
Hex.HEX_UPPER = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}
-- 小写十六进制字符集（同Java的 zzgx）
Hex.HEX_LOWER = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}

--- 字节数组转十六进制字符串（复现 bytesToStringUppercase 逻辑）
-- @param byteArr : 字节数组
-- @param uppercase : 是否大写输出
-- @param trimTrailingZero : 是否跳过末尾0x00字节（Google特有逻辑）
function Hex.bytesToString(byteArr, uppercase, trimTrailingZero)
    local chars = uppercase and Hex.HEX_UPPER or Hex.HEX_LOWER
    local len = #byteArr
    local str = {}
    local idx = 1

    for i = 1, len do
        if not trimTrailingZero or 
           i ~= len or 
           byteArr[i] ~= 0 then -- 严格复现末尾0x00跳过逻辑
            local b = byteArr[i] & 0xFF
            str[idx] = chars[(b >> 4) + 1] -- 高4位
            str[idx + 1] = chars[(b & 0x0F) + 1] -- 低4位
            idx = idx + 2
        end
    end
    return table.concat(str)
end

--- 十六进制字符串转字节数组（复现 stringToBytes 逻辑）
-- @throws 字符串长度非偶数时报错
function Hex.stringToBytes(hexStr)
    if #hexStr % 2 ~= 0 then
        error("Hex string has odd number of characters") -- 复现IllegalArgumentException
    end

    local bytes = {}
    for i = 1, #hexStr, 2 do
        local byteStr = hexStr:sub(i, i + 1)
        local byteVal = tonumber(byteStr, 16)
        if not byteVal then
            error("Invalid hex character: " .. byteStr)
        end
        bytes[(i + 1) // 2] = byteVal & 0xFF
    end
    return bytes
end

--- 解析为short数组（小端序，复现 decode_S）
function Hex.decode_S(hexStr)
    local bytes = Hex.stringToBytes(hexStr)
    if #bytes % 2 ~= 0 then
        error("Byte length must be multiple of 2 for shorts")
    end

    local shorts = {}
    for i = 1, #bytes, 2 do
        local low = bytes[i]
        local high = bytes[i + 1]
        shorts[(i + 1) // 2] = (high << 8) | low
    end
    return shorts
end

--- 解析为int数组（小端序，复现 decode_I）
function Hex.decode_I(hexStr)
    local bytes = Hex.stringToBytes(hexStr)
    if #bytes % 4 ~= 0 then
        error("Byte length must be multiple of 4 for ints")
    end

    local ints = {}
    for i = 1, #bytes, 4 do
        local b0, b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]
        ints[(i + 3) // 4] = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    end
    return ints
end

--- 解析为long数组（小端序，复现 decode_J）
function Hex.decode_J(hexStr)
    local bytes = Hex.stringToBytes(hexStr)
    if #bytes % 8 ~= 0 then
        error("Byte length must be multiple of 8 for longs")
    end

    local longs = {}
    for i = 1, #bytes, 8 do
        local lowPart = (bytes[i + 3] << 24) | (bytes[i + 2] << 16) | (bytes[i + 1] << 8) | bytes[i]
        local highPart = (bytes[i + 7] << 24) | (bytes[i + 6] << 16) | (bytes[i + 5] << 8) | bytes[i + 4]
        longs[(i + 7) // 8] = { high = highPart, low = lowPart }
    end
    return longs
end

--- 生成hexdump格式字符串（严格复现HexDumpUtils.dump()）
-- @param bArr 字节数组（Lua table）
-- @param offset 起始偏移量（从1开始）
-- @param length 转储长度
-- @param showAscii 是否显示ASCII区域
function Hex.dump(bArr, offset, length, showAscii)
    -- 参数校验（复现Java边界检查）
    if not bArr or #bArr == 0 or offset < 1 or length <= 0 or (offset + length - 1) > #bArr then
        return nil
    end

    -- 计算行缓冲区大小（复现Java的i3计算）
    local lineCapacity = 57
    if showAscii then
        lineCapacity = 75
    end
    local sb = {}
    local totalLines = math.ceil(length / 16)
    table.insert(sb, string.rep("-", 78) .. "\n")  -- 分隔线

    local currentIndex = offset
    local bytesLeft = length
    local lineByteCount = 0      -- 当前行字节计数
    local lineStartIndex = offset -- 当前行起始索引

    while bytesLeft > 0 do
        -- 行首偏移量显示（复现Java的%04X/%08X逻辑）
        if lineByteCount == 0 then
            if length < 65536 then
                table.insert(sb, string.format("%04X: ", currentIndex - 1))
            else
                table.insert(sb, string.format("%08X: ", currentIndex - 1))
            end
            lineStartIndex = currentIndex
        end

        -- 第8字节后添加分隔符（复现Java的" -"逻辑）
        if lineByteCount == 8 then
            table.insert(sb, " -")
        end

        -- 写入十六进制字节（严格保持%02X格式）
        table.insert(sb, string.format(" %02X", bArr[currentIndex] & 0xFF))

        bytesLeft = bytesLeft - 1
        lineByteCount = lineByteCount + 1
        currentIndex = currentIndex + 1

        -- ASCII区域生成（完全复现Java的字符替换逻辑）
        if showAscii and (lineByteCount == 16 or bytesLeft == 0) then
            local padding = 16 - lineByteCount
            
            -- 填充缺失字节的空位（复现Java的空格对齐）
            if padding > 0 then
                local paddingSpaces = string.rep("   ", padding)
                table.insert(sb, paddingSpaces)
                
                -- 特殊处理ASCII区域的对齐（复现Java的str追加逻辑）
                if padding >= 8 then
                    table.insert(sb, "  ")
                end
            end
            
            table.insert(sb, "  ")
            
            -- 生成ASCII字符（非打印字符替换为'.'）
            for i = 0, lineByteCount - 1 do
                local charCode = bArr[lineStartIndex + i]
                if charCode >= 32 and charCode <= 126 then
                    table.insert(sb, string.char(charCode))
                else
                    table.insert(sb, ".")
                end
            end
        end

        -- 行结束处理（复现Java的换行重置逻辑）
        if lineByteCount == 16 or bytesLeft == 0 then
            table.insert(sb, "\n")
            lineByteCount = 0
        end
    end

    table.insert(sb, string.rep("-", 78))  -- 结束分隔线
    return table.concat(sb)
end

--- 将普通字符串转换为十六进制字符串
-- @param str : 要转换的普通字符串
-- @param uppercase : 是否大写输出（可选，默认小写）
-- @param trimTrailingZero : 是否跳过末尾0x00字节（可选，默认false）
function Hex.stringToHex(str, uppercase, trimTrailingZero)
    local byteArr = {}
    for i = 1, #str do
        byteArr[i] = string.byte(str, i, i)
    end
    return Hex.bytesToString(byteArr, uppercase, trimTrailingZero)
end

--- 读取文件内容为字节数组
-- @param filePath : 文件路径
-- @return 字节数组，失败时返回 nil 和错误信息
function Hex.readFileBytes(filePath)
    local file, err = io.open(filePath, "rb") -- 二进制模式读取[6,8](@ref)
    if not file then return nil, err end
    
    local content = file:read("*a") -- 读取全部内容[7,8](@ref)
    file:close()
    
    local bytes = {}
    for i = 1, #content do
        bytes[i] = content:byte(i, i) -- 转为字节数组[3](@ref)
    end
    return bytes
end

--- 文件转十六进制字符串
-- @param filePath : 文件路径
-- @param uppercase : 是否大写输出（默认小写）
-- @param trimTrailingZero : 是否跳过末尾0x00字节
function Hex.fileToHex(filePath, uppercase, trimTrailingZero)
    local bytes, err = Hex.readFileBytes(filePath)
    if not bytes then error("读取文件失败: "..err) end
    return Hex.bytesToString(bytes, uppercase, trimTrailingZero)
end

--- 生成文件的 hexdump 格式输出
-- @param filePath : 文件路径
-- @param showAscii : 是否显示ASCII区域（默认显示）
-- @param maxLength : 最大解析长度（可选，默认全部）
function Hex.fileToHexdump(filePath, showAscii, maxLength)
    local bytes, err = Hex.readFileBytes(filePath)
    if not bytes then error("读取文件失败: "..err) end
    
    local length = maxLength or #bytes
    return Hex.dump(bytes, 1, length, showAscii ~= false) -- [1](@ref)格式复现
end

-- 新增函数：读取文件并生成 hexdump 格式输出
---@param filePath string 文件路径
---@param maxLength? number 最大解析长度（可选，默认全部）
---@return string hexdump 格式的字符串
function Hex.dumpFile(filePath, maxLength)
    -- 以二进制模式读取文件
    local file, err = io.open(filePath, "rb")
    if not file then
        error("文件打开失败: " .. (err or "未知错误"))
    end
    local content = file:read("*a") -- 读取全部内容
    file:close()

    -- 将内容转为字节数组
    local bytes = {}
    for i = 1, #content do
        bytes[i] = content:byte(i, i)
    end

    -- 调用已有 dump 函数生成结果
    local length = math.min(maxLength or math.huge, #bytes)
    return Hex.dump(bytes, 1, length, true) -- 强制启用 ASCII 区域
end

-- 新增函数：将文件转为纯十六进制字符串
---@param filePath string 文件路径
---@param uppercase? boolean 是否大写输出（默认小写）
---@return string 十六进制字符串
function Hex.fileToHexString(filePath, uppercase)
    local file, err = io.open(filePath, "rb")
    if not file then error("文件打开失败: "..err) end
    local content = file:read("*a")
    file:close()
    
    local bytes = {}
    for i = 1, #content do
        bytes[i] = content:byte(i, i)
    end
    return Hex.bytesToString(bytes, uppercase, false) -- 不跳过末尾零
end

return Hex
