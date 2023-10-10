#!/bin/bash

monitor_ram() {
    while true; do
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        ram_util=$(vm_stat | awk '/Pages active/ {print $3 * 16384 / 1024 / 1024}') 
        echo "$timestamp ; $ram_util MB" >> system_indicators.csv
        sleep 600
    done
}

start() {
    echo "Starting the background process..."
    monitor_ram & 
    monitor_pid=$(echo $!)
    echo "Process started. PID: $monitor_pid"
    echo $monitor_pid > .pidfile
}

stop() {
    if [ -e .pidfile ]; then
        pid=$(cat .pidfile)
        gpid=$(ps -o pgid= $pid)
        echo "Stopping process with GPID $gpid..."
        kill -- -$gpid
        rm .pidfile
        echo "Process stopped"
    else
        echo "No running process found"
    fi
}

get_status() {
    if [ -e .pidfile ]; then
        pid=$(cat .pidfile)
        if ps -p $pid > /dev/null; then
            echo "Process is running with PID $pid"
            retval=1
        else
            echo "Process is not running"
            rm .pidfile
            retval=0
        fi
    else
        echo "No running process found"
        retval=0
    fi

    return "$retval"
}

# Main script
case $1 in
    "START")
        get_status
        is_running=$?
        if [ $is_running == 1 ]
        then
            stop
        fi
        start
        ;;
    "STOP")
        stop
        ;;
    "STATUS")
        get_status
        ;;
    *)
        echo "Usage: $0 START|STOP|STATUS"
        exit 1
        ;;
esac

exit 0
