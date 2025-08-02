--标准库
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "com.androlua.LuaEditor"
import "android.os.Build"
import "android.os.Environment"
import "android.content.Intent"
import "android.net.Uri"
import "android.provider.Settings"
import "java.io.File"--导入File类
import "android.widget.ArrayAdapter"
import "android.widget.LinearLayout"
import "android.widget.TextView"
import "java.io.File"
import "android.widget.ListView"
import "android.app.AlertDialog"
import "android.webkit.MimeTypeMap"
--1.文件判断
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
--5.对话框
function 对话框(a,b,c,d,e,f,g,h)
  AlertDialog.Builder(this)
  .setTitle(a)
  .setMessage(b)
  .setPositiveButton(c,d)
  .setNeutralButton(e,f)
  .setNegativeButton(g,h)
  .show()
end
--6.申请所有文件访问权限
--[[原文:
  --http://t.csdn.cn/yzg2X
  --转Lua:@智仙一呀一
  --应在AndroidManifest.xml增加对应权限
  --Android11+
  import "android.net.Uri"
  import "android.provider.Settings"
  import "android.content.Intent"
  intent=Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
  intent.setData(Uri.parse("package:"..activity.getPackageName()));
  activity.startActivity(intent);
]]
-- 兼容 Lua 5.1/5.2 的 Android 文件权限管理
-- 检测 Android 版本是否 >= 11（API 30）
function isAndroid11OrAbove()
  -- 使用 tonumber 确保兼容低版本 Lua
  local sdkVersion = tonumber(tostring(Build.VERSION.SDK_INT))
  return sdkVersion and sdkVersion >= 30
end

-- 检查是否拥有所有文件访问权限（兼容低版本）
function hasAllFilesAccessPermission()
  if isAndroid11OrAbove() then
    -- 使用 pcall 避免低版本 Lua 可能的方法不存在问题
    local status, result = pcall(function()
      return Environment.isExternalStorageManager()
    end)
    return status and result
  end
  -- Android 10 及以下默认返回 true
  return true
end

-- 请求文件权限（仅 Android 11+ 生效）
function requestAllFilesAccessPermission()
  if not isAndroid11OrAbove() then
    提示("此功能仅支持 Android 11 及以上设备")
    return
  end

  if hasAllFilesAccessPermission() then
    提示("权限已授予")
    return
  end

  local intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
  intent.setData(Uri.parse("package:" .. activity.getPackageName()))
  activity.startActivity(intent)
end

function 申请所有文件权限()
  if isAndroid11OrAbove() then
    if hasAllFilesAccessPermission() then
      提示("已获得所有文件访问权限")
     else
      提示("未获得权限，正在跳转设置...")
      requestAllFilesAccessPermission()
    end
   else
    提示("当前设备无需特殊文件权限")
  end
end
--7.取文件格式
function 取文件格式(name)
  ExtensionName=tostring(name):match("%.(.+)")
  Mime=MimeTypeMap.getSingleton().getMimeTypeFromExtension(ExtensionName)
  local Mimea=Mime.."___"
  local Mimeb=Mimea:match("/(.+)___")
  return tostring(Mimeb)
end
--8.重载
function 重载()
  activity.newActivity("cz")  
end
--9.编辑器函数
bjq={
  LinearLayout;
  layout_height="match_parent";
  orientation="vertical";
  layout_width="match_parent";
  gravity="left";
  {
    TextView;
    text="最上面的按钮这一行是可以左右滑动的哟";
  };
  {
    HorizontalScrollView;
    {
      LinearLayout;
      {
        Button;
        id="cb";
        text="主界面";
      };
      {
        Button;
        id="cg";
        text="选择";
      };
      {
        EditText;
        hint="加载文件以及保存路径";
        id="cf";
      };
      {
        Button;
        id="cc";
        text="温馨提示(一定要看)";
      };
      {
        Button;
        id="cd";
        text="保存";
      };
      {
        Button;
        id="ce";
        text="读取";
      };
    };
  };
  {
    LuaEditor;
    id="ca";
  };
};
function 编辑器代码(加载)
  if 加载==nil then
   else
    cf.text=加载
              local file = io.open(cf.text, "r")
          local content = ""
          local buffer = ""

          while true do
            buffer = file:read(1024 * 1024) -- 每次读取1MB
            if buffer == nil then break end
            content = content .. buffer
          end
          file:close()

          -- 然后处理content字符串，分割成行
          local lines = {}
          for line in content:gmatch("[^\r\n]+") do
            table.insert(lines, line)
          end

          -- 食用方法
          ca.text = table.concat(lines, "\n")
          提示([[读取成功
           
           读取文件路径:]]..cf.text..[[
           
           读取内容:]]..io.open(cf.text):read("*a"))
  end
  activity.setContentView(loadlayout(bjq))--设置布局
  cb.onClick=function()
        重载()
  end
  cc.onClick=function ()
    对话框("温馨提示，请你认真看完",[[首先虽然这些内容你在教程也就是帮助里面也能看到但如果你没有来得及在教程和帮助仔细阅读的话，看这个还是很有帮助的
        
        有一件事很重要，千万不要误触到那个路径编辑框左边的选择的那个按钮了，那是选择路径的一个弹窗，点击了那个按钮以后就会弹出这个弹窗，这个时候你就找不到你加载文件的那个路径了
        
        没错，温馨提示的右边还有按钮，你可以往右滑动，最上面是一个可以左右滑动的，一个布局往右滑动，你会发现两个按钮，一个是保存，一个是加载
        
        首先是第1种情况，你突然进入了这个界面，左边的路径的输入框是被填满的，下面的加载这个文件字符的这个编辑框也是被填满的
        
        你突然进入了这个界面，发现左边的输入框内有一个文件的路径，下面的这个代码编辑框内出现了很多的字符，左边的这个路径就是这些字符对应的文件的路径，而这些。字符就是那个文件的内容，所以不要对这些字符轻易的更改，在没有清楚的了解你所加载的这个文件之前
        
        如果需要更改文件，需要三思而后行，不过即使一不小心更改了，也不用担心，因为想要彻底将这个更改的文件保存在它所对应的源文件的路径下，需要点击这个温馨提示，再往右边滑的按钮就是那个保存按钮
        
        在保存的右边还会有一个按钮是加载，也就是读取它是读取这个路径文件的一个按钮，点击了这个读取的按钮就会立刻读取这个路径文件中的内容到下面的代码编辑框中，当然这个路径也是可以修改的
        
        这个路径最好不要轻易的修改，如果你对你自己对源文件的修改有担心的话，可以在你原来的那个路径的文件名，不是文件后缀后，而是文件名就是举个例子吧a.txt，应该修改的是a和.txt之间没错，如果你对你的修改有一点点的担忧，可以修改这两个字符之间的文字就是将原本的路径例如....../a.txt修改为....../a已更改.txt，这样可以做到对原文件不会造成任何的修改，以避免原文件受到损坏，也能够达成修改源文件的目的
        
        另外还有很多重要的点，比如说刚进入该界面，不要轻易修改左边的编辑框内的文件路径，或者是将文件路径清空，以防你将最上方的布局向右滑动时误触到加载按钮导致下方的代码编辑框内的字符全部消失，当然如果发生这种事情解决办法也很简单，那就是把你删除掉的路径重新填回来就行了不过这样不就成盒不是肉泥了吗？还不如直接去那些文件管理器里面编辑呢，在这里整这么麻烦
        
        这是另外一种情况，你通过主界面的按钮进入了这个界面，在这个界面，左边的路径的编辑框是空的，下面的代码的编辑框也是空的
        
        不过在这里同样也可以支持选择文件没错在这个路径的编辑框的左边，有一个选择文件的按钮
        
        点击这个按钮，你就可以选择你想要加载的那个文件的路径选择，完成以后向右滑动，会有一个加载按钮，点击加载按钮就会加载出那个文件。注意千万不要点击保存按钮，点击保存按钮会强制将所有空白的内容覆盖在那个文件上，导致那个文件彻底损坏
        
        然后就可以尽情的修改了，不过修改保存的方式可以参考上面的一些说明]],"好的，我知道了")
  end
  cg.onClick=function ()
    ChoiceFile("/storage/emulated/0",cf.setText)
  end
  cd.onClick=function ()
    对话框("你真的要保存吗？",[[以下有三个选择可供你挑选
        
        首先是选择保存，当然这一点我是不是很介意的，因为万一你编辑的文件出现了一丝丝的差错，直接保存，会导致文件损坏，甚至是无法再次使用，这是非常严重的影响
        
        其次是选择备份保存这种保存方式会在你保存的文件后面加上后缀。没错，文件名会加上一个后缀叫做备份，这样保存下来的文件，既做到了更改原文件，又能做到不损坏原文件，还是非常推荐的，不过如果选用这种方法，最好还是记住原文件的路径
        
        最后就是选择错了，就是你点错按钮了，选择不]],"保存",{onClick=function ()
        对话框("你真的决定保存吗？","保存的后果会导致您将下面的字符串覆盖到上面路径未保存之前的原字符串。如果您在下面输入的字符串有问题，直接作出保存行为会导致文件损坏，即无法使用","保存",{onClick=function ()
            if ca.text=="" or cf.text=="" then
              提示("您的条件无法保存文件，您的路径为空或者是您在下方代码编辑框中的字符串为空，导致您无法保存文件")
             else
              f=File(tostring(File(tostring(cf.text)).getParentFile())).mkdirs()
              io.open(cf.text,"w"):write(ca.text):close()
              提示([[写入成功
                   
                   被写入文件路径:]]..cf.text..[[
                   
                   写入内容:]]..ca.text)
            end
        end},nil,nil,"点错了或者我更改我的选择")
        end},"备份保存",{onClick=function ()
        if ca.text=="" or cf.text=="" then
          提示("您的条件无法保存文件，您的路径为空或者是您在下方代码编辑框中的字符串为空，导致您无法保存文件")
         else
          local newpath=cf.text:match("(.+)").."备份."..取文件格式(cf.text)
          io.open(newpath,"w"):write(ca.text):close()
          提示([[写入成功
                   
                   被写入文件路径:]]..newpath..[[
                   
                   写入内容:]]..ca.text)
        end
    end},"点错了，不保存")
  end
  ce.onClick=function ()
    对话框("是否读取",[[读取有三种选择
    
    1.直接读取，不推荐，如果正在读取文件会出意外，导致正在读取的文件消失
      
    2.我点错了]],"直接读取",{onClick=function ()
        if cf.text=="" then
          提示("读取失败，选择文件的路径为空")
         else
          local file = io.open(cf.text, "r")
          local content = ""
          local buffer = ""

          while true do
            buffer = file:read(1024 * 1024) -- 每次读取1MB
            if buffer == nil then break end
            content = content .. buffer
          end
          file:close()

          -- 然后处理content字符串，分割成行
          local lines = {}
          for line in content:gmatch("[^\r\n]+") do
            table.insert(lines, line)
          end

          -- 食用方法
          ca.text = table.concat(lines, "\n")
          提示([[读取成功
           
           读取文件路径:]]..cf.text..[[
           
           读取内容:]]..io.open(cf.text):read("*a"))
        end
    end},nil,nil,"我点错了")
  end
end
function 编辑器(加载文件路径)
  if 加载文件路径==nil then
    编辑器代码()
   else
    编辑器代码(加载文件路径)
  end
end