--文件导入包
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "BTE"
import "help"
activity.setTitle("BTE")--设置标题
activity.setTheme(android.R.style.Theme_Material_Light_NoActionBar)--设置主题
activity.setContentView(loadlayout(layout))--设置布局
activity.setRequestedOrientation(1)--横屏0--竖屏1
local Hex=require"Hex"--导入Hex包
if file_exists("/storage/emulated/0/BTE/config/config.json")and file_exists("/storage/emulated/0/BTE/btl/btl.json") and file_exists("/storage/emulated/0/BTE/bin/bin.json")and file_exists("/storage/emulated/0/BTE/json/json.json")and file_exists("/storage/emulated/0/BTE/bak/bak.json")then
  提示("配置成功，文件存在")
 else
  提示("文件不存在，准备初始化")
  写入文件("/storage/emulated/0/BTE/config/config.json",[[
[
  {
    "name": "BTE",
    "path": "/storage/emulated/0/BTE",
    "BTL-version": 3,
    "BTL-Path": "/storage/emulated/0/BTE/btl",
    "BIN-Path": "/storage/emulated/0/BTE/bin",
    "Json-Path": "/storage/emulated/0/BTE/json",
    "Bak-Path": "/storage/emulated/0/BTE/bak",
    "Terrain-Edit": true,
    "Version": 0.01,
    "Config-Path": "/storage/emulated/0/BTE/config"
  }
]
]])
  写入文件("/storage/emulated/0/BTE/btl/btl.json",[[
[
]
]])
  写入文件("/storage/emulated/0/BTE/bin/bin.json",[[
[
]
]])
  写入文件("/storage/emulated/0/BTE/json/json.json",[[
[
]
]])
  写入文件("/storage/emulated/0/BTE/bak/bak.json",[[
[
]
]])
  提示("初始化成功")
end;
a.onClick=function()
  activity.setContentView(loadlayout(help))--设置布局
end