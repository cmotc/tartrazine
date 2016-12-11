lib:
	valac \
		-X "-FPIC -pie" \
		--gir tartrazine-0.1.gir \
		--vapidir="../tox-vapi/vapi" \
		--pkg=gio-2.0 \
		--pkg=libsoup-2.4 \
		--pkg=json-glib-1.0 \
		--pkg=libtoxcore \
		--target-glib=2.32 \
		-g \
		-H tartrazine.h \
		--library=tartrazine \
		--shared-library=tartrazine \
		-o tartrazine.o \
		--disable-warnings \
		tartrazine.vala

bot:
	valac \
		-X "-FPIC -pie" \
		--vapidir="./" \
		--pkg=gio-2.0 \
		--pkg=libsoup-2.4 \
		--pkg=json-glib-1.0 \
		--pkg=libtoxcore \
		--target-glib=2.32 \
		-g \
		-o calculon \
		calculon.vala
		#--disable-warnings \

clean:
	rm tartrazine.vapi \
		tartrazine.o \
		tartrazine.h \
		tartrazine-0.1.gir
