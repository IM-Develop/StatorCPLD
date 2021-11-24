cd output_files\
del *.done
del *.html
del *.jdi
del *.map
del *.pin
del *.rpt
del *.smsg
del *.sopcinfo
del *.summary
del *.txt
del *.sld
rem del *.pof
cd ..
del *.done
del *.html
del *.jdi
del *.map
del *.pin
del *.rpt
del *.smsg
del *.sopcinfo
del *.summary
del *.txt
rem del *.pof
del *.csv
del *.qws
del greybox_tmp\*.*
rem del db\*.*
del .qsys_edit\*.*
del incremental_db\*.*
del incremental_db\compiled_partitions\*.*
del hps_isw_handoff\*.*
del hps_isw_handoff\TestHPFQsys_hps_0\*.*
rmdir hps_isw_handoff\TestHPFQsys_hps_0
rmdir hps_isw_handoff
rmdir greybox_tmp
rmdir /s db
rmdir .qsys_edit
rmdir incremental_db\compiled_partitions
rmdir incremental_db
copy  simulation\modelsim\*.vht *.*
del simulation\modelsim\*.*
rmdir /s/q simulation\modelsim\rtl_work
rmdir /s/q simulation\modelsim\gate_work
copy *.vht simulation\modelsim\*.*
del *.vht