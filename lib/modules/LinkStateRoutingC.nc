#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

// LinkStateRoutingC.nc
configuration LinkStateRoutingC {
    provides interface LinkStateRouting;
    uses interface NeighborDiscovery; // Use the Neighbor Discovery interface
    uses interface Packet as Sender;   // Use a packet interface for sending
    uses interface AMSend;             // Use AMSend for sending messages
    uses interface Timer<TMilli> as RouteTimer; // Timer for periodic LSP sending
}

// Make sure the following module is connected to this configuration
implementation {
    components LinkStateRoutingP;
    connections
        LinkStateRoutingP.LinkStateRouting -> LinkStateRouting; // Connect LinkStateRouting
        LinkStateRoutingP.NeighborDiscovery -> NeighborDiscovery; // Connect NeighborDiscovery
        LinkStateRoutingP.Sender -> Sender; // Connect Sender interface
        LinkStateRoutingP.AMSend -> AMSend; // Connect AMSend interface
        LinkStateRoutingP.RouteTimer -> RouteTimer; // Connect RouteTimer interface
}
