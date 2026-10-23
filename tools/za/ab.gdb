set pagination off
set breakpoint pending on
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
break f_7008556bb0
commands
silent
set $x = (unsigned long*)$rdi
printf "x19=%lx x20=%lx x30=%lx\n", $x[19], $x[20], $x[30]
set $o = (unsigned long*)$x[19]
printf "pool: +0=%lx +8(block)=%lx +10=%lx +18=%lx +20=%lx +28=%lx\n", $o[0], $o[1], $o[2], $o[3], $o[4], $o[5]
set $b = (unsigned long*)$o[1]
printf "block: head=%lx n=%x cap=%x  +10=%lx +20=%lx +28=%lx +30=%lx +38=%lx\n", $b[0], ((unsigned*)$b)[2], ((unsigned*)$b)[7], $b[2], $b[4], $b[5], $b[6], $b[7]
dump binary memory /tmp/block.bin 0x7445800000 0x7445c00000
quit
end
run
dump binary memory /tmp/block.bin 0x7445800000 0x7445c00000
quit
