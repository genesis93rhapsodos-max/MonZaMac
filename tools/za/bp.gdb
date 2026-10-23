set pagination off
set breakpoint pending on
handle SIGSEGV nostop noprint pass
handle SIGBUS nostop noprint pass
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
break f_7008134154
commands
silent
printf "Initialize(this=%lx, addr=%lx, size=%lx, flag=%lx) lr=%lx\n", ((unsigned long*)$rdi)[0], ((unsigned long*)$rdi)[1], ((unsigned long*)$rdi)[2], ((unsigned long*)$rdi)[3], ((unsigned long*)$rdi)[30]
continue
end
run
quit
