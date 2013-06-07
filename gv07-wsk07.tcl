set opt(tr)     "/dev/shm/gv07-wsk07_1000.tr"
set opt(namtr)  "/dev/shm/gv07-wsk07_1000.nam"
set opt(stop)   180
set opt(node)   200
set opt(transm) 30
set opt(dest)   10
set opt(bw)	    1Gb
set opt(delay)  10ms
set opt(ll)	    LL
set opt(ifq)    Queue/DropTail
set opt(mac)    Mac/802_3
set opt(chan)   Channel

proc finish {} {
	global ns opt trfd

	$ns flush-trace
	close $trfd

	exit 0
}

proc create-trace {} {
	global ns opt
	set    trfd [open $opt(tr) w]

	$ns trace-all $trfd
	if {$opt(namtr) != ""} {
		$ns namtrace-all [open $opt(namtr) w]
	}

	return $trfd
}

# cria as maquinas do barramento
proc create-topology {} {
	global ns opt udp null
	global lan node

	for {set i 0} {$i < $opt(node)} {incr i} {
		set     node($i) [$ns node]
		lappend nodelist $node($i)

		set udp($i)      [new Agent/UDP]
		$ns attach-agent $node($i) $udp($i)
        $udp($i) set fid_ 2

		set null($i)     [new Agent/Null]
		$ns attach-agent $node($i) $null($i)
	}

	set lan [$ns newLan $nodelist $opt(bw) $opt(delay) \
			-llType $opt(ll) -ifqType $opt(ifq) \
			-macType $opt(mac) -chanType $opt(chan)]
}

## MAIN ##
set ns   [new Simulator]
set trfd [create-trace]

$ns color 1 Blue
$ns color 2 Red

create-topology

# seta as maquinas receptoras
for {set i 0} {$i < $opt(dest)} {incr i} {
	set n [expr {int(rand()*$opt(node))}]
    set dest($i) $n

	puts "Maq receptora: $n"
}

# seta as maquinas transmissoras
for {set i 0} {$i < $opt(transm)} {incr i} {
    set n [expr {int(rand()*$opt(node))}]
    set transm($i) $n

	puts "Maq transmissora: $n"
}

# cria as conexões
for {set i 0} {$i < $opt(transm)} {incr i} {
	set ndx     [expr {int(rand()*$opt(dest))}]
	set cbr($transm($i)) [new Application/Traffic/CBR]

	$cbr($transm($i)) attach-agent    $udp($transm($i))
	$cbr($transm($i)) set packetSize_ 1000
	$cbr($transm($i)) set interval_   0.05

	$ns connect $udp($transm($i)) $null($dest($ndx))

    puts "$i conectado com $ndx"

	$ns at 0.0        "$cbr($transm($i)) start"
	$ns at $opt(stop) "$cbr($transm($i)) stop"
}

$ns at $opt(stop) "finish"
$ns run
