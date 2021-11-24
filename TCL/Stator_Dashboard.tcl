#TCL script to set memory with predefined value
# set dash [$mm dashboard Stator_Dashboard "Dashboard Example" "Tools/Example"]
# dashboard_set_property $dash self visible true
# master_write_32 $mm 0x10 0x80
# close_service master $mm
	
namespace eval Stator_Dashboard {

	# set base_add 0x10
	set mm [lindex [get_service_paths master] 0]
	open_service master $mm
	
	# Create dashboard 
	variable dash_path [ add_service dashboard Stator_Dashboard "First Dashboard" "Tools/First Dashboard"]

	# Set dashboard properties
	dashboard_set_property $dash_path self visible true

	# Add widgets
	dashboard_add $dash_path myButtonWrite button self
	dashboard_set_property $dash_path myButtonWrite text "Write MDIO"
	dashboard_set_property $dash_path myButtonWrite enabled true
	
	dashboard_add $dash_path myButtonRead button self
	dashboard_set_property $dash_path myButtonRead text "Read MDIO"
	dashboard_set_property $dash_path myButtonRead enabled true
	
	# Callback for myButtonRead click
	proc Read_MDIO { } {
		variable reset
		
		set reset 1
		
		# master_write_32 $mm 0x10 0
	}
	
	proc Write_MDIO { } {
		variable OnOff
		
		set OnOff !OnOff
		# set mm [lindex [get_service_paths master] 0]
		# master_write_32 $mm 0x8 0x363
		# dashboard_add $dash_path myLightLed color red
		# dashboard_set_property $dash_path myButtonLight enabled false
	}

	# Register callbacks	
	# dashboard_set_property $dash_path myButtonWrite onClick [list ::Stator_Dashboard::Main]
	dashboard_set_property $dash_path myButtonRead onClick [list ::Stator_Dashboard::Read_MDIO]
	dashboard_set_property $dash_path myButtonWrite onClick [list ::Stator_Dashboard::Write_MDIO]
}