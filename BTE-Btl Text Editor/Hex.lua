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
  table.insert(sb, string.rep("-", 78) .. "\n") -- 分隔线

  local currentIndex = offset
  local bytesLeft = length
  local lineByteCount = 0 -- 当前行字节计数
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

  table.insert(sb, string.rep("-", 78)) -- 结束分隔线
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

function Hex.DumpToOriginalText(dumpText)
  local hexStr = ""
  -- 提取所有十六进制字节（忽略偏移量和分隔符）
  for hexByte in dumpText:gmatch("%s([0-9A-F][0-9A-F])%s") do
    hexStr = hexStr .. hexByte
  end
  -- 将十六进制字符串转为原始字节数组
  local bytes = Hex.stringToBytes(hexStr)
  -- 将字节数组转为正常字符串
  local text = ""
  for i, byte in ipairs(bytes) do
    text = text .. string.char(byte)
  end
  return text
end

function Hex.extractAsciiFromFile(filePath, chunkSize)
  local file = assert(io.open(filePath, "rb"))
  local buffer = {}
  local offset = 0
  local totalBytes = 0
  local asciiResult = {}

  -- 大文件分块处理（避免内存溢出）
  while true do
    local chunk = file:read(chunkSize or 16384) -- 默认16KB/块
    if not chunk then break end

    -- 处理当前块的字节
    for i = 1, #chunk do
      local byteVal = chunk:byte(i)
      totalBytes = totalBytes + 1

      -- 按Hexdump规则转换ASCII字符[2,10](@ref)
      if byteVal >= 0x20 and byteVal <= 0x7E then
        buffer[#buffer+1] = string.char(byteVal)
       else
        buffer[#buffer+1] = "." -- 非打印字符替换
      end

      -- 每16字节换行（模拟Hexdump格式）
      if totalBytes % 16 == 0 then
        asciiResult[#asciiResult+1] = table.concat(buffer)
        asciiResult[#asciiResult+1] = "\n"
        buffer = {}
      end
    end
  end

  -- 处理剩余不满16字节的数据
  if #buffer > 0 then
    asciiResult[#asciiResult+1] = table.concat(buffer)
  end

  file:close()
  return table.concat(asciiResult)
end

local function writeFormattedLine(outFile, offset, hexLine, asciiLine)
  -- 生成偏移量前缀 (e.g. 0000:)
  outFile:write(string.format("%04X: ", offset))

  -- 合并十六进制部分（8字节分隔符）
  for i = 1, 16 do
    if i == 9 then outFile:write("- ") end -- 分组分隔符
    outFile:write(hexLine[i] or "   ")
  end

  -- 添加ASCII区域
  outFile:write("  ")
  for i = 1, 16 do
    outFile:write(asciiLine[i] or " ")
  end
  outFile:write("\n")
end

function Hex.hexdumpToFile(dumpText, outputPath)
  local hexStr = ""
  -- 提取所有十六进制字节（忽略偏移量和分隔符）
  for hexByte in dumpText:gmatch("%s([0-9A-F][0-9A-F])%s") do
    hexStr = hexStr .. hexByte
  end
  -- 将十六进制字符串转为字节数组
  local bytes = Hex.stringToBytes(hexStr)
  -- 写入二进制文件
  local file = assert(io.open(outputPath, "wb"))
  for _, byte in ipairs(bytes) do
    file:write(string.char(byte))
  end
  file:close()
end

function Hex.dumpFileToOutput(inputPath, outputPath, maxBytes, chunkSize)
  -- 打开输入/输出文件
  local inputFile = assert(io.open(inputPath, "rb"))
  local outputFile = assert(io.open(outputPath, "w"))
  maxBytes = maxBytes or math.huge
  chunkSize = chunkSize or 4096 -- 默认分块大小4KB

  -- 初始化全局偏移量和行缓存
  local offset = 0
  local lineBuffer = {}
  local asciiBuffer = {}

  -- 写入标题分隔线
  outputFile:write("--------------------------------------------------------------\n")

  -- 分块读取循环
  while offset < maxBytes do
    local bytesRead = 0
    local data = inputFile:read(math.min(chunkSize, maxBytes - offset))
    if not data then break end

    -- 处理当前块的字节
    for i = 1, #data do
      local byteVal = data:byte(i)
      local linePos = (offset + i - 1) % 16 + 1

      -- 记录十六进制值
      table.insert(lineBuffer, string.format("%02X ", byteVal))

      -- 记录ASCII字符
      asciiBuffer[linePos] = (byteVal >= 0x20 and byteVal <= 0x7E)
      and string.char(byteVal)
      or "."

      -- 每16字节写入一行
      if linePos == 16 then
        writeFormattedLine(outputFile, offset, lineBuffer, asciiBuffer)
        lineBuffer = {}
        asciiBuffer = {}
        offset = offset + 16
      end
      bytesRead = bytesRead + 1
    end

    -- 更新全局偏移量
    offset = offset + bytesRead
  end

  -- 处理剩余不满16字节的数据
  if #lineBuffer > 0 then
    writeFormattedLine(outputFile, offset - #lineBuffer, lineBuffer, asciiBuffer)
  end

  -- 写入结束分隔线
  outputFile:write("--------------------------------------------------------------")
  inputFile:close()
  outputFile:close()
end
--最佳反转换
function Hex.DumpToOriginalFile_PLUS(inputPath, outputPath)
  -- 使用 pcall 来捕获 I/O 等操作的异常，使函数更安全
  return pcall(function()
    local inputFile = assert(io.open(inputPath, "rb"), "无法打开输入文件: " .. inputPath)
    local outputFile = assert(io.open(outputPath, "wb"), "无法创建输出文件: " .. outputPath)

    -- 优化1：使用更高效的 table.concat 和固定大小的缓冲区
    local buffer = {}
    local bufferSize = 0
    local MAX_BUFFER_SIZE = 10 * 1024 * 1024 -- 10MB 刷新阈值

    local function flushBuffer()
      if bufferSize > 0 then
        outputFile:write(table.concat(buffer))
        buffer = {}
        bufferSize = 0
      end
    end

    for line in inputFile:lines() do
      local hexData = ""
      local processLine = true

      -- 预处理：去除行首尾空白字符
      line = line:gsub("^%s+", ""):gsub("%s+$", "")

      -- 跳过空行和明显的注释行
      if #line == 0 or line:match("^[#;/]") or line:match("^%-%-") then
        processLine = false
      end

      if processLine then
        -- 模式1: 用户提供的格式 "0000: 03 00 00 00 01 00 00 00 - 00 00 00 00 02 00 00 00   ................"
        -- 捕获组1: 偏移量部分 (e.g., "0000: ")
        -- 捕获组2: 十六进制数据部分 (e.g., "03 00 00 00 01 00 00 00 - 00 00 00 00 02 00 00 00")
        -- 捕获组3: ASCII部分 (e.g., "   ................")
        local match1_offset, match1_hex, match1_ascii = line:match("^(%x+:%s+)([%x%s%-]+)(%s%s+.*)$")

        if match1_hex then
          hexData = match1_hex
         else
          -- 模式2: 标准无ASCII区格式 "0000: 48 65 6c 6c 6f 20 77 6f"
          local match2_offset, match2_hex = line:match("^(%x+:%s+)([%x%s%-]+)$")
          if match2_hex then
            hexData = match2_hex
           else
            -- 模式3: 无地址格式，但可能包含 '-' 分组符
            local match3_hex = line:match("^([%x%s%-]+)$")
            if match3_hex then
              -- 验证是否真的是十六进制数据（避免误判文本行）
              local temp_hex = match3_hex:gsub("[^0-9a-fA-F]", "")
              if #temp_hex > 0 and #temp_hex % 2 == 0 then
                hexData = match3_hex
               else
                hexData = ""
              end
            end
          end
        end

        -- 如果成功提取了十六进制数据
        if hexData and #hexData > 0 then
          -- 清洗数据：移除所有非十六进制字符（包括空格和'-'）
          hexData = hexData:gsub("[^0-9a-fA-F]", "")

          -- 检查是否有奇数个十六进制字符
          if #hexData % 2 ~= 0 then
            -- 对于奇数长度，丢弃最后一个字符
            hexData = hexData:sub(1, -2)
          end

          -- 逐字节转换并写入缓冲区
          for i = 1, #hexData, 2 do
            local byteStr = hexData:sub(i, i + 1)
            if #byteStr == 2 then
              local byteVal = tonumber(byteStr, 16)
              if byteVal ~= nil then
                table.insert(buffer, string.char(byteVal))
                bufferSize = bufferSize + 1
              end
            end
          end

          -- 缓冲区达到阈值时刷新到磁盘
          if bufferSize >= MAX_BUFFER_SIZE then
            flushBuffer()
          end
        end
      end
    end

    -- 关键修复：写入所有剩余的缓冲数据
    flushBuffer()

    inputFile:close()
    outputFile:close()
    return true
  end)
end

-- 增强版本：带详细错误报告和统计信息
function Hex.DumpToOriginalFileVerbose(inputPath, outputPath)
  local stats = {
    totalLines = 0,
    processedLines = 0,
    skippedLines = 0,
    totalBytes = 0,
    warnings = {}
  }

  local success, result = pcall(function()
    local inputFile = assert(io.open(inputPath, "rb"), "无法打开输入文件: " .. inputPath)
    local outputFile = assert(io.open(outputPath, "wb"), "无法创建输出文件: " .. outputPath)

    local buffer = {}
    local bufferSize = 0
    local MAX_BUFFER_SIZE = 10 * 1024 * 1024

    local function flushBuffer()
      if bufferSize > 0 then
        outputFile:write(table.concat(buffer))
        buffer = {}
        bufferSize = 0
      end
    end

    for line in inputFile:lines() do
      stats.totalLines = stats.totalLines + 1
      local originalLine = line
      line = line:gsub("^%s+", ""):gsub("%s+$", "")

      local processLine = true
      if #line == 0 or line:match("^[#;/]") or line:match("^%-%-") then
        stats.skippedLines = stats.skippedLines + 1
        processLine = false
      end

      if processLine then
        local hexData = ""
        local matched = false

        -- 模式1: 用户提供的格式 "0000: 03 00 00 00 01 00 00 00 - 00 00 00 00 02 00 00 00   ................"
        local match1_offset, match1_hex, match1_ascii = line:match("^(%x+:%s+)([%x%s%-]+)(%s%s+.*)$")

        if match1_hex then
          hexData = match1_hex
          matched = true
         else
          -- 模式2: 标准无ASCII区格式 "0000: 48 65 6c 6c 6f 20 77 6f"
          local match2_offset, match2_hex = line:match("^(%x+:%s+)([%x%s%-]+)$")
          if match2_hex then
            hexData = match2_hex
            matched = true
           else
            -- 模式3: 无地址格式，但可能包含 '-' 分组符
            local match3_hex = line:match("^([%x%s%-]+)$")
            if match3_hex then
              -- 验证是否真的是十六进制数据（避免误判文本行）
              local temp_hex = match3_hex:gsub("[^0-9a-fA-F]", "")
              if #temp_hex > 0 and #temp_hex % 2 == 0 then
                hexData = match3_hex
                matched = true
              end
            end
          end
        end

        if not matched then
          stats.skippedLines = stats.skippedLines + 1
          local maxLen = math.min(#originalLine, 50)
          table.insert(stats.warnings, string.format("第%d行无法识别格式: %s", stats.totalLines, originalLine:sub(1, maxLen)))
         else
          stats.processedLines = stats.processedLines + 1

          -- 清洗数据：移除所有非十六进制字符（包括空格和'-'）
          hexData = hexData:gsub("[^0-9a-fA-F]", "")

          if #hexData % 2 ~= 0 then
            table.insert(stats.warnings, string.format("第%d行包含奇数个十六进制字符，已截断", stats.totalLines))
            hexData = hexData:sub(1, -2)
          end

          -- 转换并写入
          for i = 1, #hexData, 2 do
            local byteStr = hexData:sub(i, i + 1)
            -- 确保 byteStr 长度为 2，避免 tonumber 错误
            if #byteStr == 2 then
              local byteVal = tonumber(byteStr, 16)
              if byteVal ~= nil then -- 检查 tonumber 是否成功
                table.insert(buffer, string.char(byteVal))
                bufferSize = bufferSize + 1
                stats.totalBytes = stats.totalBytes + 1
               else
                table.insert(stats.warnings, string.format("第%d行发现无效十六进制字节: %s", stats.totalLines, byteStr))
              end
             else
              table.insert(stats.warnings, string.format("第%d行发现不完整十六进制字节对: %s", stats.totalLines, byteStr))
            end
          end

          if bufferSize >= MAX_BUFFER_SIZE then
            flushBuffer()
          end
        end
      end
    end

    flushBuffer()
    inputFile:close()
    outputFile:close()
    return stats
  end)

  if success then
    return true, result
   else
    return false, result
  end
end

-- 使用示例：
--[[
-- 基本使用
local success, err = Hex.DumpToOriginalFile_PLUS("dump.txt", "restored.bin")
if success then
  print("文件还原成功！")
else
  print("文件还原失败: " .. tostring(err))
end

-- 详细模式使用
local success, stats = Hex.DumpToOriginalFileVerbose("dump.txt", "restored.bin")
if success then
  print(string.format("还原完成！处理了%d/%d行，生成%d字节", 
    stats.processedLines, stats.totalLines, stats.totalBytes))
  if #stats.warnings > 0 then
    print("警告信息:")
    for _, warning in ipairs(stats.warnings) do
      print("  " .. warning)
    end
  end
else
  print("还原失败: " .. tostring(stats))
end
--]]
return Hex