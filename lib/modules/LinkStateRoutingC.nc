// Project 1
// CSE 160
// LinkStateRoutingC.nc
// Sep/28/2024
// Zaid Laffta
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"


configuration LinkStateRoutingC {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery;
    uses interface SimpleSend;
    uses interface Timer<TMilli> as LSRTimer;
}
implementation {
    components LinkStateRoutingP, NeighborDiscoveryC, SimpleSendC, TimerMilliC;
    
    LinkStateRouting = LinkStateRoutingP;
    NeighborDiscovery = NeighborDiscoveryC;
    SimpleSend = SimpleSendC as SimpleSendCInstance;
    LSRTimer = TimerMilliC as LSRTimerInstance;
}
