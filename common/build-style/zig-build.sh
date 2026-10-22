do_build() {
	local zig_target zig_cpu zig_search_prefix

	# TODO: This duplication between build-profiles and cross-profiles
	# is totally unnecessary. It would be nice if there was some way to
	# avoid it.
	#
	if [ "$CROSS_BUILD" ]; then
		zig_target="${XBPS_CROSS_ZIG_TARGET}"
		zig_cpu="${XBPS_CROSS_ZIG_CPU}"
	fi

	# Inform zig of the required libc include paths.
	cat > xbps_zig_libc.txt <<-EOF
		include_dir=${XBPS_CROSS_BASE}/usr/include
		sys_include_dir=${XBPS_CROSS_BASE}/usr/include
		crt_dir=${XBPS_CROSS_BASE}/usr/lib
		gcc_dir=$($CC -print-file-name="")
		msvc_lib_dir=
		kernel32_lib_dir=
		darwin_sdk_dir=
	EOF

	# The Zig build system only has a single install step, there is no
	# way to build artifacts for a given prefix and then install those artifacts
	# to that prefix at some later time. Therefore, we build and install to the zig-out
	# directory and later copy the artifacts to the destdir in do_install().
	# We use zig-out to avoid path conflicts as it is the default install
	# prefix used by the zig build system.
	cross_args=""
	if [ "$CROSS_BUILD" ]; then
		cross_args="-Dtarget=${zig_target} -Dcpu=${zig_cpu}"
	fi

	ZIG_GLOBAL_CACHE_DIR=/host/zig DESTDIR="zig-out" zig build \
		${makejobs} \
		--sysroot "${XBPS_CROSS_BASE:-/}" \
		--search-prefix /usr \
		--prefix /usr \
		--libc xbps_zig_libc.txt \
		--release=safe \
		--verbose \
		${cross_args} \
		install \
		${configure_args}
}

do_install() {
	cp -r zig-out/* "${DESTDIR}"
}
