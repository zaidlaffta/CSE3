
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
/*
configuration NeighborDiscoveryC {
    // Provides the NeighborDiscovery interface to other modules.
    provides interface NeighborDiscovery;
}

implementation {

    // Uses the NeighborDiscoveryP module to implement the NeighborDiscovery interface.
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;


    //Wiring for the NeighborDiscovery module
    // The RandomC component is used for generating random numbers,
    components RandomC as Random;
    NeighborDiscoveryP.Random -> Random;
    
    // TimerMilliC is a timer that fires periodically which was giving in the lab lecture
    components new TimerMilliC() as Timer;
    NeighborDiscoveryP.Timer -> Timer;

    // SimpleSendC component for sending messages using Active Messages (AM).
    components new SimpleSendC(AM_PACK);
    // This will be used to broadcast discovery messages to neighboring nodes.
    NeighborDiscoveryP.Sender -> SimpleSendC;

    // HashmapC is used to store discovered neighbors, it can discover up to 20 nighbors
    components new HashmapC(uint32_t, 22);
    NeighborDiscoveryP.NeighborTable -> HashmapC;
}
*/

configuration NeighborDiscoveryC {
    // Provides the NeighborDiscovery interface to other modules.
    provides interface NeighborDiscovery;
}

implementation {

    // NeighborDiscoveryP provides the actual implementation of NeighborDiscovery interface
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    // Setup of RandomC for generating random values
    components RandomC as RandomGen;
    NeighborDiscoveryP.Random -> RandomGen;

    // TimerMilliC handles periodic timer events
    components new TimerMilliC() as PeriodicTimer;
    NeighborDiscoveryP.Timer -> PeriodicTimer;

    // SimpleSendC for broadcasting packets
    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.Broadcast -> SimpleSendC;

    // HashmapC is a storage component for neighbor information (up to 20 neighbors)
    components new HashmapC(uint32_t, 22);
    NeighborDiscoveryP.NeighborCache -> HashmapC;
}
