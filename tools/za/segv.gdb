set pagination off
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGSEGV stop print
run
printf "slot=%lx\n", *(unsigned long*)0x7003d9b0f8
print hle_slots[152].name
print hle_slots[152].fn
quit
