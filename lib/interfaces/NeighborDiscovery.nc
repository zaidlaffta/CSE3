
//CSE160
//Project 1
#include "../../includes/packet.h"
interface NeighborDiscovery {
	
	command error_t start();
   	command void discover(pack* packet);
   	command void printNeighborList();

	command void getNeighborCount();
	//command void printNeighbors();
   	command uint32_t* getNeighbors();
   	command uint16_t getNeighborListSize();
	
    



}