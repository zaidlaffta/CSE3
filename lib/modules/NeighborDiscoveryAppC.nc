configuration NeighborDiscoveryAppC {
    uses interface Boot;
    uses interface AMSend;
    uses interface Receive;
    uses interface Timer<TMilli>;
}

implementation {
    components MainC, ActiveMessageC, TimerMilliC, NeighborDiscoveryC;

    NeighborDiscoveryC.Boot -> MainC.Boot;
    NeighborDiscoveryC.AMSend -> ActiveMessageC.AMSend[AM_NEIGHBOR_TYPE];  // AM Type for Neighbor Discovery
    NeighborDiscoveryC.Receive -> ActiveMessageC.Receive[AM_NEIGHBOR_TYPE];
    NeighborDiscoveryC.Timer -> TimerMilliC;
}
