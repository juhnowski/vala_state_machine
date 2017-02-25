rm tst
valac --thread --pkg gio-2.0 --pkg json-glib-1.0 test.vala -o tst
./tst
