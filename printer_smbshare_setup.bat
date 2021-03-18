@echo off
:start
cls
echo. 
echo 按任意键开始安装打印机，或按右上角 X 退出安装
echo.
echo 本程序会先删除原有的打印机，再新建打印机
echo.
echo 如果遇到错误，点击确定后，重新运行本程序即可
echo.
echo 打印机驱动依赖网络共享路径，如无法访问共享，则先输入3建立共享
echo.
echo 输入【1】自动识别IP安装
echo.
echo 输入【2】手动输入IP安装
echo.
echo 输入【3】建立共享（普通权限）
echo.
set printname=NPIBB7209 (HP Color LaserJet MFP M277dw)
set drivername=HP Color LaserJet Pro MFP M277 PCL-6
set driverfloder86=\\192.168.0.10\XXX\001-安装包\HP_Color_LaserJet_Pro_MFP_M277\hpne3B2A4_x86.inf
set driverfloder64=\\192.168.0.10\XXX\001-安装包\HP_Color_LaserJet_Pro_MFP_M277\hpne3B2A4_x64.inf
set /p choice="请选择执行步骤："
if "%choice%"=="1" goto default
if "%choice%"=="2" goto newIP
if "%choice%"=="3" goto setupshare
goto start

:newIP
cls
echo.
echo 如打印机IP已更换，则使用本步骤，输入新IP
echo.
echo 如不知道打印机IP，可在打印机面板点击网络图标查看
echo.
set /p ip="请输入打印机IP:"
goto setupprinter

:default
cls
echo.
echo 正在获取打印机IP
echo.
for /f "tokens=2 delims=[]" %%a in ('ping -n 1 NPIBB7209^|findstr "Ping"') do (
echo 自动识别到的打印机IP是 " %%a "
set ip=%%a
)
goto setupprinter

:setupprinter
echo 删除同名打印机
echo.
rundll32 printui.dll,PrintUIEntry /dl /n "%printname%" /q
echo 创建打印机 TCP/IP 端口：IP_%ip%
echo.
cscript %windir%\System32\Printing_Admin_Scripts\zh-CN\prnport.vbs -a -r IP_%ip% -h %ip% -o raw >nul
echo 创建打印机： %printname%
echo.
if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
	rundll32 printui.dll,PrintUIEntry /if /b "%printname%" /f %driverfloder64% /r "IP_%ip%" /m "%drivername%" /z
	rundll32 printui.dll,PrintUIEntry /n "%printname%" /y
) else (
	rundll32 printui.dll,PrintUIEntry /if /b "%printname%" /f %driverfloder86% /r "IP_%ip%" /m "%drivername%" /z
	rundll32 printui.dll,PrintUIEntry /n "%printname%" /y
)
goto result

:result
echo 已设置%printname%为默认打印机
echo.
echo 正在完成打印机安装，请稍等
echo.
ping 127.0.0.1 -n 10 >nul
start control Printers
echo 如果系统较慢，新安装的打印机会显示在“未指定”中，稍等就好了
echo.
echo 安装完成，按任意键退出...
echo.
pause>nul&exit

:setupshare
net use * /del /y
cmdkey /add:192.168.0.10 /user:normal /pass:123456
net use Z: \\192.168.0.10\XXX /persistent:yes /savecred
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##192.168.0.10#XXX /v _LabelFromReg /d "XXX" /f
net use Y: \\192.168.0.10\打印机扫描 /persistent:yes /savecred
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##192.168.0.10#打印机扫描 /v _LabelFromReg /d "打印机扫描" /f
for /f "tokens=2,*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop"') do (
set desk=%%j
)
set SrcFile=Z:\
set LnkFile=%desk%\XXX
call :CreateShort "%SrcFile%" "%LnkFile%"
set SrcFile2=Y:\
set LnkFile2=%desk%\打印机扫描
call :CreateShort "%SrcFile2%" "%LnkFile2%"
goto :eof
:CreateShort
mshta VBScript:Execute("Set a=CreateObject(""WScript.Shell""):Set b=a.CreateShortcut(""%~2.lnk""):b.TargetPath=""%~1"":b.WorkingDirectory=""%~dp1"":b.Save:close")
echo 按任意键返回&pause>nul&goto start
