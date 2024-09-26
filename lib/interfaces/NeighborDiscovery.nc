

//CSE160
//Project 1
#include "../../includes/packet.h"

/*
interface NeighborDiscovery {
    
    command error_t initialize();
    command void processDiscovery(pack* message);
    command void displayNeighbors();
    command uint32_t* fetchNeighbors();
    command uint16_t fetchNeighborCount();
    
}
*/
interface NeighborDiscovery {
    command error_t initialize();
    command void processDiscovery(pack* message);
    command uint32_t* fetchNeighbors();
    command uint16_t fetchNeighborCount();
    command void displayNeighbors();
    command void clearExpiredNeighbors();  // New function
    command uint16_t getNeighborTTL(uint32_t neighbor);  // New function
}
