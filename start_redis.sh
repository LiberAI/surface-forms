#!/usr/bin/env bash
nohup redis-server --port 7979 --dbfilename surface-forms.rdb --dir ./db &
echo "Check logs in 'nohup.out'."
