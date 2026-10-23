set pagination off
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGSEGV nostop noprint pass
handle SIGINT stop print nopass
run
thread apply all bt 60
kill
quit
