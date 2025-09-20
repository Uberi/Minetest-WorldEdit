#!/bin/bash
tempdir=$(mktemp -d)
confpath=$tempdir/minetest.conf
worldpath=$tempdir/world
modlist=(
	worldedit
	worldedit_commands
)
trap 'rm -rf "$tempdir"' EXIT

[ -f worldedit/mod.conf ] || { echo "Must be run in modpack root folder." >&2; exit 1; }

mtserver=
if [ "$1" == "--docker" ]; then
	command -v docker >/dev/null || { echo "Docker is not installed." >&2; exit 1; }
	[ -d minetest_game ] || echo "A source checkout of minetest_game was not found. This can fail if your docker image does not ship a game." >&2;
else
	mtserver=$(command -v luantiserver)
	[[ -z "$mtserver" && -x ../../bin/luantiserver ]] && mtserver=../../bin/luantiserver
	[ -z "$mtserver" ] && { echo "To run the test outside of Docker, an installation of luantiserver is required." >&2; exit 1; }
fi

mkdir $worldpath
printf '%s\n' mg_name=singlenode '[end_of_params]' >$worldpath/map_meta.txt
printf '%s\n' worldedit_run_tests=true max_forceloaded_blocks=9999 >$confpath

if [ -z "$mtserver" ]; then
	chmod -R 777 $tempdir
	[ -n "$DOCKER_IMAGE" ] || { echo "Missing DOCKER_IMAGE env variable" >&2; exit 1; }
	vol=(
		-v "$confpath":/etc/minetest/minetest.conf
		-v "$tempdir":/var/lib/minetest/.minetest
	)
	for mod in "${modlist[@]}"; do
		vol+=(-v "$PWD/$mod":/var/lib/minetest/.minetest/world/worldmods/$mod)
	done
	[ -d minetest_game ] && vol+=(
		-v "$PWD/minetest_game":/var/lib/minetest/.minetest/games/minetest_game
	)
	docker run --rm -i "${vol[@]}" "$DOCKER_IMAGE"
else
	mkdir $worldpath/worldmods
	for mod in "${modlist[@]}"; do
		ln -s "$PWD/$mod" $worldpath/worldmods/$mod
	done
	$mtserver --config "$confpath" --world "$worldpath" --logfile /dev/null
fi

test -f $worldpath/tests_ok || exit 1
exit 0
