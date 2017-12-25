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
		rm -f *tgz

install:
	mkdir -p /usr/share/vala-0.26/vapi \
		/usr/share/vala-0.34/vapi \
		/usr/share/vala-0.36/vapi \
		/usr/share/vala/vapi \
		/usr/local/share/vala/vapi
	cp -vf \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.36/vapi/tartrazine.vapi
	cp -vf \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.36/vapi/tartrazine.deps
	cp -vf \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.34/vapi/tartrazine.vapi
	cp -vf \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.34/vapi/tartrazine.deps
	cp -vf \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.26/vapi/tartrazine.vapi
	cp -vf \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala-0.26/vapi/tartrazine.deps
	cp -vf \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/share/vala/vapi/tartrazine.vapi
	cp -vf \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/share/vala/vapi/tartrazine.deps
	cp -vf \
		tartrazine.vapi \
		$(DESTDIR)$(PREFIX)/usr/local/share/vala/vapi/tartrazine.vapi
	cp -vf \
		tartrazine.deps \
		$(DESTDIR)$(PREFIX)/usr/local/share/vala/vapi/tartrazine.deps
	cp -vf \
		tartrazine.so \
		$(DESTDIR)$(PREFIX)/usr/lib/tartrazine.so
	cp -vf \
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
	checkinstall --install=no \
		--deldoc=yes \
		--deldesc=yes \
		--delspec=yes \
		--default \
		--pkgname=tartrazine \
		--pkgversion=0.9 \
		--pakdir=../
