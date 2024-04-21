# m([<mode>] "msg" [IF <condition>])
#
# No mode means STATUS, to remove the '--' from the front
# you need to explicitely pass NOTICE
#
function (m)
	cmake_parse_arguments(M "" "" IF ${ARGN})

	if (M_KEYWORDS_MISSING_VALUES)
		message(FATAL_ERROR "Missing values for IF")
	endif()

	# Condition
	list(JOIN M_IF " " condition)
	if (DEFINED M_IF)
		set(condition_defined TRUE)
	else()
		set(condition_defined FALSE)
	endif()

	# message(mode mesg)
	list(LENGTH M_UNPARSED_ARGUMENTS argc)
	if (argc EQUAL 0)
		message("")
	else()
		if (argc GREATER_EQUAL 2)
			list(POP_FRONT M_UNPARSED_ARGUMENTS mode)
			set(mesg "${M_UNPARSED_ARGUMENTS}")
		else()
			list(APPEND modes NOTICE STATUS FATAL_ERROR VERBOSE DEPRECATION)
			if (M_UNPARSED_ARGUMENTS IN_LIST modes)
				set(mode "${M_UNPARSED_ARGUMENTS}")
				set(mesg "")
			else()
				set(mode STATUS)
				set(mesg "${M_UNPARSED_ARGUMENTS}")
				string(REPLACE "\"" "\\\"" mesg ${mesg})
			endif()
		endif()


		# Evaluate
		cmake_language(EVAL CODE "
				if ((NOT ${condition_defined}) OR (${condition}))
					message(${mode} \"${mesg}\")
				endif()
				"
			)
	endif()
endfunction()


function (section s)
	m()
	m("\t${s}")
	m(STATUS)
endfunction()
