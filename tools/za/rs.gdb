set pagination off
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
break hle_nvnSamplerPoolRegisterSampler
commands
silent
printf "enter: c=%p x29=%lx pool=%lx host=%lx id=%ld sampler=%lx host=%lx\n", c, c->x[29], c->x[0], *(unsigned long*)c->x[0], c->x[1], c->x[2], *(unsigned long*)c->x[2]
printf "  pool count=%d entries=%p\n", ((int*)*(unsigned long*)c->x[0])[2], ((void**)*(unsigned long*)c->x[0])[2]
set $cc = c
finish
end
run
quit
