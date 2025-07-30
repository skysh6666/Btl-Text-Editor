require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
activity.setTitle("BTE")
activity.setTheme(android.R.style.Theme_Material_Light_NoActionBar)
activity.setContentView(loadlayout(layout))
activity.setRequestedOrientation(1)--横屏0--竖屏1
