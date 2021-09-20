#!/bin/bash
tempdir=/tmp/mt
confpath=$tempdir/minetest.conf
worldpath=$tempdir/world

use_docker=y
[ -x ../../bin/minetestserver ] && use_docker=

rm -rf $tempdir
mkdir -p $worldpath
# the docker image doesn't have devtest
[ -n "$use_docker" ] || printf '%s\n' gameid=devtest >$worldpath/world.mt
printf '%s\n' mg_name=singlenode '[end_of_params]' >$worldpath/map_meta.txt
printf '%s\n' worldedit_run_tests=true max_forceloaded_blocks=9999 >$confpath

if [ -n "$use_docker" ]; then
	chmod -R 777 $tempdir
	docker run --rm -i \
		-v $confpath:/etc/minetest/minetest.conf \
		-v $tempdir:/var/lib/minetest/.minetest \
		-v "$PWD/worldedit":/var/lib/minetest/.minetest/world/worldmods/worldedit \
		registry.gitlab.com/minetest/minetest/server:${MINETEST_VER}
else
	mkdir $worldpath/worldmods
	ln -s "$PWD/worldedit" $worldpath/worldmods/worldedit
	../../bin/minetestserver --config $confpath --world $worldpath --logfile /dev/null
fi

test -f $worldpath/tests_ok || exit 1
exit 0
