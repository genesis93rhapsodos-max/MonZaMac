set pagination off
set breakpoint pending on
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGSEGV nostop noprint pass
break plat_reserve_guest
commands
silent
delete
watch -l *(unsigned long*)0x7445ad4e80
commands
silent
printf "write: now=%lx\n", *(unsigned long*)0x7445ad4e80
bt 4
continue
end
continue
end
run
quit
