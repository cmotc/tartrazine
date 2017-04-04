lib:
	valac \
		-X "-FPIC -pie" \
		--gir tartrazine-0.1.gir \
		--pkg=gio-2.0 \
		--pkg=libsoup-2.4 \
		--pkg=json-glib-1.0 \
		--pkg=libtoxcore \
		--target-glib=2.32 \
		-g \
		-H tartrazine.h \
		--library=tartrazine \
		--shared-library=tartrazine \
		-o tartrazine.so \
		--disable-warnings \
		tartrazine.vala

bot:
	valac \
		-X "-FPIC -pie -ltartrazine" \
		--vapidir="./" \
		--pkg=tartrazine \
		--target-glib=2.32 \
		-g \
		-o calculon \
		calculon.vala
		#--disable-warnings \

clean:
	rm tartrazine.vapi \
		tartrazine.so \
		tartrazine.h \
		tartrazine-0.1.gir \
		calculon \
		build.err \
		build.log \

install:
	cp -v \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.34/vapi/tartrazine.vapi
	cp -v \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.34/vapi/tartrazine.deps
	cp -v \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.26/vapi/tartrazine.vapi
	cp -v \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.26/vapi/tartrazine.deps
	cp -v \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala/vapi/tartrazine.vapi
	cp -v \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala/vapi/tartrazine.deps
	cp -v \
		tartrazine.so \
		$(DESTDIR)$(PREFIX)/usr/lib/tartrazine.so
	cp -v \
		tartrazine.h \
		$(DESTDIR)$(PREFIX)/usr/include/tartrazine.h

uninstall:
	rm -v \
		/usr/share/vala-0.34/vapi/tartrazine.vapi \
		/usr/share/vala/vapi/tartrazine.vapi \
		/usr/lib/tartrazine.so \
		/usr/include/tartrazine.h \
		/usr/bin/calculon

deb-pkg:
	make
	checkinstall --install=no \
	--default \
	--pkgname=tartrazine \
	--pkgversion=0.9 \
	--pakdir=../
