proc QryBuild {tableSelected whereTmp } {
    global RETURN_FLAG SELECTEDTABLE
    global  tableColumnArray tableList funcList
    set RETURN_FLAG 0
    set SELECTEDTABLE $tableSelected
    
    if {$SELECTEDTABLE == "empty"} {
	set SELECTEDTABLE "event"
    }
    if {$whereTmp == "empty"} {
	if {$SELECTEDTABLE == "event"} {
	    set whereTmp "WHERE event.sid = sensor.sid AND "
	} else {
	    set whereTmp "WHERE sessions.sid = sensor.sid AND "
	}
    }

    # Grab the current pointer locations
    set xy [winfo pointerxy .]
    
    # Create the window
    set qryBldWin [toplevel .qryBldWin]
    wm title $qryBldWin "Query Builder"
    wm geometry $qryBldWin +[lindex $xy 0]+[lindex $xy 1]
    
    # Create some arrays for the lists
    # funclist are lists of {LABEL FUNCTION} pairs.  In most cases they will be the same.
    set mlst [list Tables Functions]
    set funcList(main) [list Common Strings Comparison Logical DateTime DateMacros]
    set funcList(maintables) [list Categories]
    set funcList(Common) [list {INET_ATON() INET_ATON()} {LIMIT LIMIT} {LIKE LIKE} {AND AND} {OR OR} {NOT NOT}]
    set funcList(Strings) [list {LIKE LIKE} {REGEXP REGEXP} {RLIKE RLIKE}]
    set funcList(Logical) [list {AND AND} {OR OR} {NOT NOT} {BETWEEN() BETWEEN()} {LIKE LIKE}]
    set funcList(Comparison) [list {= =} {!= !=} {< <} {> >} {<=> <=>}]
    set funcList(DateTime) [list {TO_DAYS() TO_DAYS()} {UNIX_TIMESTAMP() UNIX_TIMESTAMP} {UTC_TIMESTAMP() UTC_TIMESTAMP}]
    set funcList(DateMacros) [list [list TODAYUTC '[lindex [GetCurrentTimeStamp] 0]'] \
	    [list LASTWEEK '[lindex [GetCurrentTimeStamp "1 week ago"] 0]'] \
	    [list YESTERDAY '[lindex [GetCurrentTimeStamp "1 day ago"] 0]']]
    set funcList(Categories) [list {CATI event.status=11} {CATII event.status=12} {CATIII event.status=13} \
	    {CATIV event.status=14} {CATV event.status=15} {CATVI event.status=16} {CATVII event.status=17} \
	    {NA event.status=1} {RealTime event.status=0} {Escalated event.status=2}]
    foreach tableName $tableList {
	set funcList($tableName) $tableColumnArray($tableName)
    }
    
    # Main Frame
    set mainFrame [frame $qryBldWin.mFrame -background #dcdcdc -borderwidth 1]

    
    set qryTypeBox [radiobox $mainFrame.qTypeBox -orient horizontal -labeltext "Select Query Type" -labelpos n -foreground darkblue]
      $qryTypeBox add event -text "Events" -selectcolor red -foreground black
      $qryTypeBox add sessions -text "Sessions" -selectcolor red -foreground black
   
    if {$SELECTEDTABLE == "event"} {
	$qryTypeBox select event
    } else {
	$qryTypeBox select sessions
    }
    $qryTypeBox configure -command {typeChange}

    set editFrame [frame $mainFrame.eFrame -background black -borderwidth 1]
      set editBox [scrolledtext $editFrame.eBox -textbackground white -vscrollmode dynamic \
		-sbwidth 10 -hscrollmode none -wrap word -visibleitems 60x10 -textfont ourFixedFont \
		-labeltext "Edit Where Clause"]
      
      if { ![string match -nocase limit $whereTmp] } { set whereTmp "$whereTmp  LIMIT 500" }
      $editBox insert end $whereTmp
      $editBox mark set insert "end -11 c"
      set bb [buttonbox $mainFrame.bb]
      $bb add Submit -text "Submit" -command "set RETURN_FLAG 1"
      $bb add Cancel -text "Cancel" -command "set RETURN_FLAG 0"
      #pack $bb -side top -fill x -expand true

    set mainBB1 [buttonbox $editFrame.mbb1 -padx 0 -pady 0 -orient vertical]
      foreach logical $funcList(Logical) {
	  set command "$editBox insert insert \"[lindex $logical 1] \""
	  $mainBB1 add [lindex $logical 0] -text [lindex $logical 0] -padx 0 -pady 0 -command "$command"
      }
    set mainBB2 [buttonbox $editFrame.mbb2 -padx 0 -pady 0 -orient vertical]
      foreach comparison $funcList(Comparison) {
	  set command "$editBox insert insert \"[lindex $comparison 1] \""
	  $mainBB2 add [lindex $comparison 0] -text [lindex $comparison 0] -padx 0 -pady 0 -command "$command"
      }
      pack $mainBB1 -side left -fill y
      pack $editBox -side left -fill both -expand true
      pack $mainBB2 -side left -fill y

    set selectFrame [frame $mainFrame.sFrame -background black -borderwidth 1]
      set catList [scrolledlistbox $selectFrame.cList -labeltext Categories \
	      -selectioncommand "updateItemList $selectFrame" -sbwidth 10\
	      -labelpos n -vscrollmode static -hscrollmode dynamic \
	      -visibleitems 20x10 -foreground darkblue -textbackground lightblue]
      set metaList [scrolledlistbox $selectFrame.mList -labeltext Meta -sbwidth 10\
	      -selectioncommand "updateCatList $selectFrame" \
	      -hscrollmode dynamic \
	      -labelpos n -vscrollmode static \
	      -visibleitems 20x10 -foreground darkblue -textbackground lightblue]
      set itemList [scrolledlistbox $selectFrame.iList -hscrollmode dynamic -sbwidth 10\
	     -dblclickcommand "addToEditBox $editBox $selectFrame" \
	     -scrollmargin 5 -labeltext "Items" \
	     -labelpos n -vscrollmode static -hscrollmode static\
	     -visibleitems 20x10 -foreground darkblue -textbackground lightblue]
  
      pack $metaList $catList $itemList -side left -fill both -expand true
      iwidgets::Labeledwidget::alignlabels $metaList $catList $itemList
    pack $qryTypeBox -side top -fill none -expand false
    pack $editFrame -side top -fill both -expand yes
    #pack  $mainBB1 $mainBB2 -side top -fill none -expand false
    pack  $selectFrame $bb -side top -fill both -expand true -pady 1
    eval $metaList insert 0 $mlst
    pack $mainFrame -side top -pady 1 -expand true -fill both

    




    tkwait variable RETURN_FLAG
    set returnWhere [list cancel cancel]
    if {$RETURN_FLAG} {
        # No \n for you!
        regsub -all {\n} [$editBox get 0.0 end] {} returnWhere
	set returnWhere "[list $SELECTEDTABLE $returnWhere]"
    } else {
	set returnWhere [list cancel cancel]
    }
    destroy $qryBldWin
    return $returnWhere  
}


proc updateCatList { selectFrame } {
    global funcList metaSelection SELECTEDTABLE
     
    $selectFrame.cList delete 0 end
    #$selectFrame.cList delete entry 0 end
    $selectFrame.iList delete 0 end
    
    set sel [$selectFrame.mList getcurselection]
    set metaSelection $sel
#    puts $tableSelected
    if {$sel == "Tables"} { 
	if { $SELECTEDTABLE == "event" } {
	    set localTableList [list event data icmphdr tcphdr udphdr sensor]
	} else {
	    set localTableList [list sessions sensor]
	}
	eval $selectFrame.cList insert 0 $localTableList
    } else {
	eval $selectFrame.cList insert 0 $funcList(main)
	if { $SELECTEDTABLE == "event" } {
	    eval $selectFrame.cList insert end $funcList(maintables)
	}
    }
}
    
proc updateItemList { selectFrame} {
    global funcList catSelection metaSelection
    
    $selectFrame.iList delete 0 end
    #$selectFrame.iList delete entry 0 end
    
    eval set sel [$selectFrame.cList getcurselection]
    set catSelection $sel
    if {$metaSelection == "Tables"} {
	eval $selectFrame.iList insert 0 $funcList($sel)
    } else {
	foreach i $funcList($sel) {
	    eval $selectFrame.iList insert end [lindex $i 0]
	}
    }
}

proc addToEditBox { editBox selectFrame } {
    global catSelection metaSelection funcList
    
    
    #if Meta is set to table, prepend tablename. to the item
    if {$metaSelection == "Tables"} {
	set addText [lindex [$selectFrame.iList getcurselection] 0]
	set addText "$catSelection.$addText"
    } else {
	set addText [lindex [lindex $funcList($catSelection) [$selectFrame.iList curselection]]  1]
    }
    
    $editBox insert insert "$addText "
}

proc typeChange {} {
    global SELECTEDTABLE
    set mainFrame .qryBldWin.mFrame
    $mainFrame.eFrame.eBox delete 0.0 end
    $mainFrame.sFrame.iList delete 0 end
    $mainFrame.sFrame.cList delete 0 end
    
    if {[$mainFrame.qTypeBox get] == "event" } {
	$mainFrame.eFrame.eBox insert end "WHERE event.sid = sensor.sid AND  LIMIT 500"
	set SELECTEDTABLE "event"
    } else {
	set SELECTEDTABLE "sessions"
	$mainFrame.eFrame.eBox insert end "WHERE sessions.sid = sensor.sid  LIMIT 500"
    }
    $mainFrame.eFrame.eBox mark set insert "end -11 c"
    # return $tableSelected
}

