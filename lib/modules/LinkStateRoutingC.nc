#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"

#define AM_ROUTING 63

configuration LinkStateRoutingC{
	provides interface LinkStateRouting;
	//provides interface Receive;
}

implementation{
	components LinkStateRoutingP;
	components new TimerMilliC() as PeriodicTimer;
	components new SimpleSendC(AM_ROUTING);
	components new AMReceiverC(AM_ROUTING);

	components NeighborDiscoveryC;
	LinkStateRoutingP.NeighborDiscovery -> NeighborDiscoveryC;
	
	LinkStateRouting = LinkStateRoutingP.LinkStateRouting;
	Receive = LinkStateRoutingP.LinkStateRoutingReceive;

	LinkStateRoutingP.Sender -> SimpleSendC;
	LinkStateRoutingP.Receive -> AMReceiverC;
	LinkStateRoutingP.PeriodicTimer -> PeriodicTimer;

}