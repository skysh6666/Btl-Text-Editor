--标准库
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
--1.文件判断
import "java.io.File"--导入File类
--使用io
function file_exists(path)
local f=io.open(path,'r')
if f~=nil then io.close(f) return true else return false end
end
--2.文件创建
function 写入文件(路径,内容)
  import "java.io.File"
  f=File(tostring(File(tostring(路径)).getParentFile())).mkdirs()
  io.open(tostring(路径),"w"):write(tostring(内容)):close()
end
--3.提示
function 提示(提示内容)
  Toast.makeText(activity, 提示内容,Toast.LENGTH_SHORT).show()
end
--4.选择文件
import "android.widget.ArrayAdapter"
import "android.widget.LinearLayout"
import "android.widget.TextView"
import "java.io.File"
import "android.widget.ListView"
import "android.app.AlertDialog"
function ChoiceFile(StartPath,callback)
  --创建ListView作为文件列表
  lv=ListView(activity).setFastScrollEnabled(true)
  --创建路径标签
  cp=TextView(activity)
  lay=LinearLayout(activity).setOrientation(1).addView(cp).addView(lv)
  ChoiceFile_dialog=AlertDialog.Builder(activity)--创建对话框
  .setTitle("选择文件")
  .setView(lay)
  .show()
  adp=ArrayAdapter(activity,android.R.layout.simple_list_item_1)
  lv.setAdapter(adp)
  function SetItem(path)
    path=tostring(path)
    adp.clear()--清空适配器
    cp.Text=tostring(path)--设置当前路径
    if path~="/" then--不是根目录则加上../
      adp.add("../")
    end
    ls=File(path).listFiles()
    if ls~=nil then
      ls=luajava.astable(File(path).listFiles()) --全局文件列表变量
      table.sort(ls,function(a,b)
        return (a.isDirectory()~=b.isDirectory() and a.isDirectory()) or ((a.isDirectory()==b.isDirectory()) and a.Name<b.Name)
      end)
    else
      ls={}
    end
    for index,c in ipairs(ls) do
      if c.isDirectory() then--如果是文件夹则
        adp.add(c.Name.."/")
      else--如果是文件则
        adp.add(c.Name)
      end
    end
  end
  lv.onItemClick=function(l,v,p,s)--列表点击事件
    项目=tostring(v.Text)
    if tostring(cp.Text)=="/" then
      路径=ls[p+1]
    else
      路径=ls[p]
    end

    if 项目=="../" then
      SetItem(File(cp.Text).getParentFile())
    elseif 路径.isDirectory() then
      SetItem(路径)
    elseif 路径.isFile() then
      callback(tostring(路径))
      ChoiceFile_dialog.hide()
    end

  end

  SetItem(StartPath)
end

--ChoiceFile(StartPath,callback)
--第一个参数为初始化路径,第二个为回调函数
--非原创