TGZ_TARGET=vaf3.tgz
TBZ_TARGET=vaf3.tbz
ZIP_TARGET=vaf3.zip

tgz: prepare_dir
	cd distrib/ ; tar cfz ../${TGZ_TARGET} *; cd -

tbz: prepare_dir
	cd distrib/ ; tar cfj ../${TBZ_TARGET} *; cd -

zip: prepare_dir
	cd distrib/ ; zip ../${ZIP_TARGET} *; cd -

prepare_dir:
	mkdir -p distrib
	rm -rf distrib/*
	cp execs/*EXE distrib
	cp -r data/* distrib/
	cp docs/VAFMAN01.txt distrib/
	cp README distrib/

clean:
	rm -rf distrib ${TGZ_TARGET} ${TBZ_TARGET} ${ZIP_TARGET}