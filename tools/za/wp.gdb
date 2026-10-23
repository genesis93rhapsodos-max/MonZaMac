set pagination off
set breakpoint pending on
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
break f_700176eb90
commands
silent
delete
set $fp29 = (unsigned long*)($rdi + 232)
watch -l *$fp29 if *$fp29 == 0
commands
bt 6
quit
end
continue
end
run
quit
