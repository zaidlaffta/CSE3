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
}

implementation {
    // Wiring the LinkStateRouting interface to the module
    components LinkStateRoutingP as LSRP;
    LinkStateRouting = LSRP;
}
