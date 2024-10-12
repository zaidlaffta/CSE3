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
configuration LinkStateRoutingC{
	provides interface LinkStateRouting;
}

implementation{
	components LinkStateRoutingP;
	components new TimerMilliC() as rebuildLinkStateRoutingTimer;
	components new SimpleSendC(AM_PACK);

    components new HashmapC(destination_node, 1024) as LinkStateRoutingC;
    LinkStateRoutingP.LinkStateRouting -> LinkStateRoutingC;

    components new HashmapC(destination_node, 1024) as UnvisitedNodesC;
    LinkStateRoutingP.unvisitedNodes -> UnvisitedNodesC;

	components NeighborDiscoveryC;
	LinkStateRoutingP.NeighborDiscovery -> NeighborDiscoveryC;
	
	LinkStateRouting = LinkStateRoutingP.LinkStateRouting;

	LinkStateRoutingP.Sender -> SimpleSendC;
	LinkStateRoutingP.rebuildLinkStateRoutingTimer -> rebuildLinkStateRoutingTimer;
}