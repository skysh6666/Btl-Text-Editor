--文件导入包模块
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "BTE"
--初始化模块
function main()
  layout={
    LinearLayout;
    layout_height="fill";
    gravity="left";
    layout_width="fill";
    orientation="vertical";
    {
      TextView;
      text="BTE-Btl Text Editor";
      textSize="25";
    };
    {
      LinearLayout;
      {
        Button;
        id="a";
        text="教程";
      };
      {
        Button;
        id="b";
        text="HEX-16进制转换（测试）";
      };
      {
        Button;
        id="c";
        text="文件编辑";
      };
    };
    {
      LinearLayout;
      {
        Button;
        id="d";
        text="文件配置";
      };
      {
        Button;
        id="e";
        text="btl+bin编辑";
      };
      {
        Button;
        id="";
        text="";
      };
    };
  };
  activity.setTitle("BTE")--设置标题
  activity.setTheme(android.R.style.Theme_Material_Light_NoActionBar)--设置主题
  activity.setContentView(loadlayout(layout))--设置布局
  activity.setRequestedOrientation(1)--横屏0--竖屏1
  申请所有文件权限()
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
  --布局大全模块
  help={
    LinearLayout;
    layout_width="fill";
    orientation="horizontal";
    layout_height="fill";
    {
      ScrollView;
      layout_width="match_parent";
      layout_height="match_parent";
      {
        LinearLayout;
        layout_width="match_parent";
        orientation="vertical";
        layout_height="match_parent";
        {
          TextView;
          text="教程-Help";
          textSize="35";
        };
        {
          TextView;
          text=[[1.Hex16test.
        首先在主界面点击Hex16转换测试按钮
        你会发现来到一个界面这个界面的标题下方有一个文本输入框
        你需要做的事情非常简单，点击文本输入框下边的按钮，选择路径的那个按钮就可以选择路径了
        选择完成以后，文本输入框内会自动填写你选择的那个路径
        然后根据指示，按照你选择路径的文件格式进行操作
        例如
        如果你选择了文件格式后缀为bin/btl的文件
        就请按第1个按钮，而不是第2个按钮，第2个按钮会导致文件转换错误
        如果你选择了文件名后缀为(已转换为16进制)
        就请按第2个按钮，而不是第1个按钮，否则会发生转换错误
        2.编辑界面教程
       
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
        
        然后就可以尽情的修改了，不过修改保存的方式可以参考上面的一些说明
        ]];
          textSize="25";
        };
      };
    };
  };
  hex16={
    LinearLayout;
    layout_height="fill";
    layout_width="fill";
    {
      ScrollView;
      layout_height="match_parent";
      layout_width="match_parent";
      {
        LinearLayout;
        orientation="vertical";
        layout_height="match_parent";
        layout_width="match_parent";
        {
          TextView;
          textSize="45";
          text="Hex16test";
        };
        {
          LinearLayout;
          orientation="vertical";
          {
            EditText;
            hint="输入待转换文件路径（.bin/.btl/.txt）";
            id="ba";
            text="1";
          };
          {
            Button;
            text="选择路径";
            id="bf";
          };
        };
        {
          TextView;
          textSize="20";
          text="提示:转换后结果在转换前文件的同目录下，文件名与转换前文件几乎一致，文件名后缀多了转换说明";
        };
        {
          Button;
          text="普通二进制文件即bin/btl转txt";
          id="bb";
        };
        {
          Button;
          text="普通16进制文件即txt转bin/btl";
          id="bc";
        };
        {
          TextView;
          textSize="20";
          text="文件转换情况";
        };
        {
          TextView;
          text="此时文件未转换";
          id="bd";
        };
        {
          Button;
          text="文件转换后内容";
          id='bg',
        };
      };
    };
  };
  --逻辑处理模块
  --帮助help
  a.onClick=function()
    activity.setContentView(loadlayout(help))--设置布局
  end
  --hex16测试
  b.onClick=function()
    activity.setContentView(loadlayout(hex16))--设置布局
    bg.Text = [[此时文件未转换]]
    bf.onClick=function()
      ChoiceFile("/storage/emulated/0",ba.setText)
    end
    bb.onClick=function()
      对话框("最后选择","选择是或否决定是否转换文件","是",{onClick=function()
          local filename=File(ba.text).getName()
          if filename:match("(.+).btl")==nil then
            if filename:match("(.+).bin")==nil then
              提示("请确保你选择的文件后缀名为btl或bin")
             else
            end
           else
            local outpath=ba.text:match("(.+).btl").."(已转换为16进制).txt"
            Hex.dumpFileToOutput(ba.text,outpath)
            提示([[转换成功，被转换文件路径:]]..ba.text..[[
          
          转换后文件路径:]]..outpath)
            bd.setText([[转换成功，被转换文件路径:]]..ba.text..[[
          
          转换后文件路径:]]..outpath)
            bg.Text = [[文件转换内容]]
            bg.onClick=function ()
              编辑器(outpath)
            end
          end
      end},nil,nil,"否",nil)
    end
    bc.onClick=function()
      对话框("最后选择","选择是或否决定是否转换文件","是",{onClick=function()
          local filename=File(ba.text).getName()
          if filename:match("(.+).txt")==nil then
            提示("请确保你选择的文件后缀名为txt")
           else
            local outpath=ba.text:match("(.+).txt").."(已转换回二进制).txt"
            local success, stats = Hex.DumpToOriginalFileVerbose(ba.text, outpath)
            if success then
              提示(string.format("还原完成！处理了%d/%d行，生成%d字节",
              stats.processedLines, stats.totalLines, stats.totalBytes))
              if #stats.warnings > 0 then
                提示("警告信息:")
                for _, warning in ipairs(stats.warnings) do
                  提示("  " .. warning)
                end
              end
             else
              提示("还原失败: " .. tostring(stats))
            end
            提示([[转换成功，被转换文件路径:]]..ba.text..[[
          
          转换后文件路径:]]..outpath)
            bd.setText([[转换成功，被转换文件路径:]]..ba.text..[[
          
          转换后文件路径:]]..outpath)
            bg.Text = [[文件转换内容]]
            bg.onClick=function ()
              编辑器(outpath)
            end
          end
      end},nil,nil,"否",nil)
    end
  end
  c.onClick=function ()
    编辑器()
  end
end