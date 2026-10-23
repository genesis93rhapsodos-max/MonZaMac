# Drive the Ryujinx window: focus it, then a sequence "KEY:ms,KEY+KEY:ms,wait:ms,..." (keys held for ms; '+' holds
# several at once), optional screenshot afterwards. Ryujinx keyboard map here: A=Z B=X X=C Y=V, L stick WASD,
# R stick IJKL, L=E R=U ZL=Q ZR=O, Plus/Minus = numpad keys "Add"/"Subtract".
param([string]$seq = "", [string]$shot = "")
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices; using System.Collections.Generic;
public class RK {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  public struct RECT { public int L, T, R, B; }
  public static IntPtr Game(uint pid) {
    IntPtr best = IntPtr.Zero;
    EnumWindows((h, x) => { uint p; GetWindowThreadProcessId(h, out p); var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
      if (p == pid && IsWindowVisible(h) && sb.ToString().Contains("Z-A")) best = h; return true; }, IntPtr.Zero);
    return best;
  }
  public static void Key(byte vk, bool down) {
    byte sc = (byte)MapVirtualKey(vk, 0);
    keybd_event(vk, sc, down ? 0u : 2u, UIntPtr.Zero);
  }
}
"@
$p = Get-Process Ryujinx -ErrorAction Stop | Select-Object -First 1
$h = [RK]::Game([uint32]$p.Id)
if ($h -eq [IntPtr]::Zero) { "no game window"; exit 1 }
[RK]::ShowWindow($h, 9) | Out-Null
[RK]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
$vk = @{ A=0x41; B=0x42; C=0x43; D=0x44; E=0x45; F=0x46; H=0x48; I=0x49; J=0x4A; K=0x4B; L=0x4C; O=0x4F; Q=0x51; S=0x53;
         U=0x55; V=0x56; W=0x57; X=0x58; Z=0x5A; Add=0x6B; Subtract=0x6D; Up=0x26; Down=0x28; Left=0x25; Right=0x27; Return=0x0D }
foreach ($step in ($seq -split ',')) {
  if (-not $step) { continue }
  $k, $ms = $step -split ':'
  if ($k -eq 'wait') { Start-Sleep -Milliseconds ([int]$ms); continue }
  $keys = $k -split '\+'
  foreach ($x in $keys) { [RK]::Key([byte]$vk[$x], $true) }
  Start-Sleep -Milliseconds ([int]$ms)
  foreach ($x in $keys) { [RK]::Key([byte]$vk[$x], $false) }
  Start-Sleep -Milliseconds 120
}
if ($shot) {
  $r = New-Object RK+RECT; [RK]::GetWindowRect($h, [ref]$r) | Out-Null
  $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
  $g = [System.Drawing.Graphics]::FromImage($bmp); $dc = $g.GetHdc()
  [RK]::PrintWindow($h, $dc, 2) | Out-Null; $g.ReleaseHdc($dc)
  $bmp.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png)
  "shot $shot"
}
