

//CSE160
//Project 1
#include "../../includes/packet.h"
interface NeighborDiscovery {
    
    command error_t initialize();
    command void processDiscovery(pack* message);
    command void displayNeighbors();
    command uint32_t* fetchNeighbors();
    command uint16_t fetchNeighborCount();
    
}
