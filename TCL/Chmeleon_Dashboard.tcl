#TCL script to set memory with predefined value
# set dash [$mm dashboard Chmeleon_Dashboard "Dashboard Example" "Tools/Example"]
# dashboard_set_property $dash self visible true
# master_write_32 $mm 0x10 0x80
# close_service master $mm
	
namespace eval Chmeleon_Dashboard {

	# set base_add 0x10
	set mm [lindex [get_service_paths master] 0]
	open_service master $mm
	
	# Create dashboard 
	variable dash_path [ add_service dashboard Chmeleon_Dashboard "First Dashboard" "Tools/First Dashboard"]

	# Set dashboard properties
	dashboard_set_property $dash_path self visible true

	# Add widgets
	dashboard_add $dash_path myButtonStart button self
	dashboard_set_property $dash_path myButtonStart text "Start Counter"
	dashboard_set_property $dash_path myButtonStart enabled true
	dashboard_add $dash_path myButtonReset button self
	
	dashboard_set_property $dash_path myButtonReset text "Reset Counter"
	dashboard_set_property $dash_path myButtonReset enabled false
	dashboard_add $dash_path myLabelCount label self
	
	dashboard_set_property $dash_path myLabelCount text "0"
	
	dashboard_add $dash_path myButtonLight button self
	dashboard_set_property $dash_path myButtonLight text "On/Off Leds"
	dashboard_set_property $dash_path myButtonLight enabled true
	
	dashboard_add $dash_path myLightLed led self
	# dashboard_add $dash_path myLightLed color red
	# dashboard_add $dash_path myLightLed text "Led On/Off"
	
	dashboard_add $dash_path myDial dial self
	dashboard_set_property $dash_path myDial title "Motor Speed"
	dashboard_set_property $dash_path myDial min 0.0
	dashboard_set_property $dash_path myDial max 255.0
	dashboard_set_property $dash_path myDial preferredHeight 300
	dashboard_set_property $dash_path myDial preferredWidth 500
	dashboard_set_property $dash_path myDial tickSize 10
	dashboard_set_property $dash_path myDial value 0
	dashboard_set_property $dash_path myDial enabled true

	set reset 0
	set OnOff 1

	# Callback for myButtonStart click
	proc count { c } {
		variable dash_path
		variable reset
		variable MotorData
		variable OnOff
		
		set mm [lindex [get_service_paths master] 0]
		
		incr c
		dashboard_set_property $dash_path myLabelCount text $c

		dashboard_set_property $dash_path myButtonStart enabled false
		dashboard_set_property $dash_path myButtonReset enabled true
		
		set MotorData [master_read_32 $mm 0x10 1]
		
		incr MotorData 327685
		
		if { !$OnOff }
		{
			master_write_32 $mm 0x8 0x0
			dashboard_add $dash_path myLightLed color red_off
		}
		else
		{
			master_write_32 $mm 0x8 0x363
			dashboard_add $dash_path myLightLed color red
		}
		
		if { !$reset } {
			
			after 1000 ::Chmeleon_Dashboard::count $c
			dashboard_set_property $dash_path myDial value [expr $MotorData&255]
			master_write_32 $mm 0x10 $MotorData
			
		} else {
			set reset 0
			set c 0
			dashboard_set_property $dash_path myLabelCount text $c
			dashboard_set_property $dash_path myButtonStart enabled true
			dashboard_set_property $dash_path myButtonReset enabled false
			dashboard_set_property $dash_path myDial value 0
			master_write_32 $mm 0x10 0x0
		}
	} 

	# Callback for myButtonReset click
	proc reset_counter { } {
		variable reset
		
		set reset 1
		
		# master_write_32 $mm 0x10 0
	}
	
	proc OnOffLeds { } {
		variable OnOff
		
		set OnOff !OnOff
		# set mm [lindex [get_service_paths master] 0]
		# master_write_32 $mm 0x8 0x363
		# dashboard_add $dash_path myLightLed color red
		# dashboard_set_property $dash_path myButtonLight enabled false
	}

	# Register callbacks	
	dashboard_set_property $dash_path myButtonStart onClick [list ::Chmeleon_Dashboard::count 0]
	dashboard_set_property $dash_path myButtonReset onClick [list ::Chmeleon_Dashboard::reset_counter]
	dashboard_set_property $dash_path myButtonLight onClick [list ::Chmeleon_Dashboard::OnOffLeds]
}