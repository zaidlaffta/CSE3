configuration NeighborDiscovery {  
    provides interface StdControl;  
    uses interface Packet;  
    uses interface AMSend;  
    uses interface Receive;  
    uses interface Timer<TMilli> as NeighborTimer;  
}  
  
implementation {  
    components NeighborDiscoveryC;  
    NeighborDiscoveryC.Packet -> ActiveMessageC.Packet;  
    NeighborDiscoveryC.AMSend -> ActiveMessageC.AMSend[AM_BROADCAST_ADDR];  
    NeighborDiscoveryC.Receive -> ActiveMessageC.Receive[AM_BROADCAST_ADDR];  
    NeighborDiscoveryC.NeighborTimer -> TimerMilliC;  
}  
