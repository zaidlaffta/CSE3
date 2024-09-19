configuration NeighborDiscovery {
    provides interface StdControl;
    uses interface Packet;
    uses interface AMSend;
    uses interface Receive;
    uses interface Timer<TMilli> as NeighborTimer;
}

implementation {
    components NeighborDiscoveryC, ActiveMessageC, new TimerMilliC() as NeighborTimerC;

    // Wiring interfaces
    NeighborDiscoveryC.Packet -> ActiveMessageC.Packet;
    NeighborDiscoveryC.AMSend -> ActiveMessageC.AMSend[TOS_BCAST_ADDR];  // Use TOS_BCAST_ADDR for broadcasting
    NeighborDiscoveryC.Receive -> ActiveMessageC.Receive[TOS_BCAST_ADDR];
    NeighborDiscoveryC.NeighborTimer -> NeighborTimerC;
}
